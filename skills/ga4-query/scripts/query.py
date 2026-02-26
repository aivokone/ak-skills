#!/usr/bin/env python3
"""GA4 Data API CLI — subcommand-based query tool for Google Analytics 4."""

import argparse
import json
import re
import sys
from pathlib import Path

import yaml
from google.analytics.admin_v1beta import AnalyticsAdminServiceClient
from google.analytics.data_v1beta import BetaAnalyticsDataClient
from google.analytics.data_v1beta.types import (
    DateRange,
    Dimension,
    Filter,
    FilterExpression,
    FilterExpressionList,
    Metric,
    NumericValue,
    OrderBy,
    RunRealtimeReportRequest,
    RunReportRequest,
)
from google.oauth2 import service_account

GA4_SCOPE = ["https://www.googleapis.com/auth/analytics.readonly"]

DEFAULT_CONFIG_LOCATIONS = [
    Path("./ga4-config.yaml"),
    Path.home() / ".config" / "ga4-query" / "ga4-config.yaml",
]

SETUP_MSG = """\
ga4-config.yaml not found.

Searched:
  1. --config flag (not provided)
  2. ./ga4-config.yaml
  3. ~/.config/ga4-query/ga4-config.yaml

Create one with:

  property_id: "YOUR_PROPERTY_ID"
  credentials_json: "/path/to/service-account.json"

Then re-run the command."""


# ── Config ────────────────────────────────────────────────────────────────────

def find_config(explicit_path=None):
    if explicit_path:
        p = Path(explicit_path)
        if p.is_file():
            return p
        print(f"Config not found: {explicit_path}", file=sys.stderr)
        sys.exit(1)
    for loc in DEFAULT_CONFIG_LOCATIONS:
        if loc.expanduser().is_file():
            return loc.expanduser()
    print(SETUP_MSG, file=sys.stderr)
    sys.exit(1)


def load_config(path):
    with open(path) as f:
        cfg = yaml.safe_load(f)
    if not isinstance(cfg, dict):
        print("Error: ga4-config.yaml is empty or invalid", file=sys.stderr)
        sys.exit(1)
    property_id = str(cfg.get("property_id", ""))
    creds_path = cfg.get("credentials_json", "")
    if not property_id:
        print("property_id missing in config", file=sys.stderr)
        sys.exit(1)
    if not creds_path:
        print("credentials_json missing in config", file=sys.stderr)
        sys.exit(1)
    return property_id, creds_path


def get_credentials(creds_path):
    return service_account.Credentials.from_service_account_file(
        creds_path, scopes=GA4_SCOPE
    )


def get_data_client(creds_path):
    return BetaAnalyticsDataClient(credentials=get_credentials(creds_path))


def get_admin_client(creds_path):
    return AnalyticsAdminServiceClient(credentials=get_credentials(creds_path))


# ── Filter parsing ────────────────────────────────────────────────────────────

FILTER_PATTERNS = [
    (r"^(.+?)!=(.+)$", "not_exact"),
    (r"^(.+?)==(.+)$", "exact"),
    (r"^(.+?)=~(.+)$", "contains"),
    (r"^(.+?)=\^(.+)$", "begins_with"),
    (r"^(.+?)=\$(.+)$", "ends_with"),
    (r"^(.+?)=\*(.+)$", "in_list"),
    (r"^(.+?)>=(.+)$", "gte"),
    (r"^(.+?)<=(.+)$", "lte"),
    (r"^(.+?)>(.+)$", "gt"),
    (r"^(.+?)<(.+)$", "lt"),
]


def parse_single_filter(filter_str):
    for pattern, op in FILTER_PATTERNS:
        m = re.match(pattern, filter_str)
        if not m:
            continue
        field, value = m.group(1).strip(), m.group(2).strip()

        if op == "exact":
            return FilterExpression(filter=Filter(
                field_name=field,
                string_filter=Filter.StringFilter(
                    match_type=Filter.StringFilter.MatchType.EXACT, value=value
                ),
            ))
        elif op == "not_exact":
            return FilterExpression(not_expression=FilterExpression(filter=Filter(
                field_name=field,
                string_filter=Filter.StringFilter(
                    match_type=Filter.StringFilter.MatchType.EXACT, value=value
                ),
            )))
        elif op == "contains":
            return FilterExpression(filter=Filter(
                field_name=field,
                string_filter=Filter.StringFilter(
                    match_type=Filter.StringFilter.MatchType.CONTAINS, value=value
                ),
            ))
        elif op == "begins_with":
            return FilterExpression(filter=Filter(
                field_name=field,
                string_filter=Filter.StringFilter(
                    match_type=Filter.StringFilter.MatchType.BEGINS_WITH, value=value
                ),
            ))
        elif op == "ends_with":
            return FilterExpression(filter=Filter(
                field_name=field,
                string_filter=Filter.StringFilter(
                    match_type=Filter.StringFilter.MatchType.ENDS_WITH, value=value
                ),
            ))
        elif op == "in_list":
            return FilterExpression(filter=Filter(
                field_name=field,
                in_list_filter=Filter.InListFilter(values=value.split(",")),
            ))
        else:
            num_ops = {
                "gt": Filter.NumericFilter.Operation.GREATER_THAN,
                "gte": Filter.NumericFilter.Operation.GREATER_THAN_OR_EQUAL,
                "lt": Filter.NumericFilter.Operation.LESS_THAN,
                "lte": Filter.NumericFilter.Operation.LESS_THAN_OR_EQUAL,
            }
            return FilterExpression(filter=Filter(
                field_name=field,
                numeric_filter=Filter.NumericFilter(
                    operation=num_ops[op],
                    value=NumericValue(double_value=float(value)),
                ),
            ))

    print(f"Invalid filter syntax: {filter_str}", file=sys.stderr)
    sys.exit(1)


def build_dimension_filter(filter_strings):
    if not filter_strings:
        return None
    exprs = [parse_single_filter(f) for f in filter_strings]
    if len(exprs) == 1:
        return exprs[0]
    return FilterExpression(and_group=FilterExpressionList(expressions=exprs))


# ── Response serialization ────────────────────────────────────────────────────

def serialize_report_response(response, dim_names, met_names):
    rows = []
    for row in response.rows:
        r = {}
        for i, dv in enumerate(row.dimension_values):
            r[dim_names[i]] = dv.value
        for i, mv in enumerate(row.metric_values):
            r[met_names[i]] = mv.value
        rows.append(r)
    return {
        "row_count": response.row_count,
        "rows": rows,
        "metadata": {"dimensions": dim_names, "metrics": met_names},
    }


# ── JSON passthrough filter parsing ──────────────────────────────────────────

def _parse_filter_json(filter_dict):
    if "andGroup" in filter_dict:
        return FilterExpression(and_group=FilterExpressionList(
            expressions=[_parse_filter_json(e) for e in filter_dict["andGroup"]["expressions"]]
        ))
    if "orGroup" in filter_dict:
        return FilterExpression(or_group=FilterExpressionList(
            expressions=[_parse_filter_json(e) for e in filter_dict["orGroup"]["expressions"]]
        ))
    if "notExpression" in filter_dict:
        return FilterExpression(not_expression=_parse_filter_json(filter_dict["notExpression"]))
    if "filter" in filter_dict:
        f = filter_dict["filter"]
        field_name = f.get("fieldName", "")
        if "stringFilter" in f:
            sf = f["stringFilter"]
            match_map = {
                "EXACT": Filter.StringFilter.MatchType.EXACT,
                "BEGINS_WITH": Filter.StringFilter.MatchType.BEGINS_WITH,
                "ENDS_WITH": Filter.StringFilter.MatchType.ENDS_WITH,
                "CONTAINS": Filter.StringFilter.MatchType.CONTAINS,
                "FULL_REGEXP": Filter.StringFilter.MatchType.FULL_REGEXP,
                "PARTIAL_REGEXP": Filter.StringFilter.MatchType.PARTIAL_REGEXP,
            }
            return FilterExpression(filter=Filter(
                field_name=field_name,
                string_filter=Filter.StringFilter(
                    match_type=match_map.get(sf.get("matchType", "EXACT"), Filter.StringFilter.MatchType.EXACT),
                    value=sf.get("value", ""),
                    case_sensitive=sf.get("caseSensitive", False),
                ),
            ))
        if "inListFilter" in f:
            ilf = f["inListFilter"]
            return FilterExpression(filter=Filter(
                field_name=field_name,
                in_list_filter=Filter.InListFilter(values=ilf.get("values", [])),
            ))
        if "numericFilter" in f:
            nf = f["numericFilter"]
            op_map = {
                "EQUAL": Filter.NumericFilter.Operation.EQUAL,
                "LESS_THAN": Filter.NumericFilter.Operation.LESS_THAN,
                "LESS_THAN_OR_EQUAL": Filter.NumericFilter.Operation.LESS_THAN_OR_EQUAL,
                "GREATER_THAN": Filter.NumericFilter.Operation.GREATER_THAN,
                "GREATER_THAN_OR_EQUAL": Filter.NumericFilter.Operation.GREATER_THAN_OR_EQUAL,
            }
            val = nf.get("value", {})
            return FilterExpression(filter=Filter(
                field_name=field_name,
                numeric_filter=Filter.NumericFilter(
                    operation=op_map.get(nf.get("operation", "EQUAL"), Filter.NumericFilter.Operation.EQUAL),
                    value=NumericValue(
                        int64_value=val.get("int64Value")) if "int64Value" in val else NumericValue(
                        double_value=val.get("doubleValue", 0)),
                ),
            ))
    return FilterExpression()


def _build_report_from_json(spec, property_id):
    dims = [Dimension(name=d) for d in spec.get("dimensions", [])]
    mets = [Metric(name=m) for m in spec.get("metrics", [])]
    date_ranges = [DateRange(**dr) for dr in spec.get("dateRanges", [])]
    req = RunReportRequest(
        property=f"properties/{property_id}",
        dimensions=dims,
        metrics=mets,
        date_ranges=date_ranges,
    )
    if "dimensionFilter" in spec:
        req.dimension_filter = _parse_filter_json(spec["dimensionFilter"])
    if "metricFilter" in spec:
        req.metric_filter = _parse_filter_json(spec["metricFilter"])
    if "limit" in spec:
        req.limit = int(spec["limit"])
    if "orderBys" in spec:
        obs = []
        for ob in spec["orderBys"]:
            kwargs = {"desc": ob.get("desc", False)}
            if "metric" in ob:
                kwargs["metric"] = OrderBy.MetricOrderBy(metric_name=ob["metric"]["metricName"])
            elif "dimension" in ob:
                kwargs["dimension"] = OrderBy.DimensionOrderBy(dimension_name=ob["dimension"]["dimensionName"])
            obs.append(OrderBy(**kwargs))
        req.order_bys = obs
    return req


# ── Subcommand handlers ──────────────────────────────────────────────────────

def cmd_report(args, property_id, creds_path):
    if args.json:
        spec = json.loads(args.json)
        req = _build_report_from_json(spec, property_id)
        client = get_data_client(creds_path)
        response = client.run_report(req)
        dim_names = [d.name for d in req.dimensions]
        met_names = [m.name for m in req.metrics]
        return serialize_report_response(response, dim_names, met_names)

    if not args.metrics:
        print("--metrics / -m is required", file=sys.stderr)
        sys.exit(1)

    dim_names = args.dimensions.split(",") if args.dimensions else []
    met_names = args.metrics.split(",")
    start = args.start or "7daysAgo"
    end = args.end or "yesterday"

    req = RunReportRequest(
        property=f"properties/{property_id}",
        dimensions=[Dimension(name=d) for d in dim_names],
        metrics=[Metric(name=m) for m in met_names],
        date_ranges=[DateRange(start_date=start, end_date=end)],
    )

    dim_filter = build_dimension_filter(args.filter)
    if dim_filter:
        req.dimension_filter = dim_filter

    if args.order_by:
        desc = args.desc or args.order_by.startswith("-")
        name = args.order_by.lstrip("-")
        if name in met_names:
            req.order_bys = [OrderBy(metric=OrderBy.MetricOrderBy(metric_name=name), desc=desc)]
        else:
            req.order_bys = [OrderBy(dimension=OrderBy.DimensionOrderBy(dimension_name=name), desc=desc)]

    if args.limit:
        req.limit = args.limit

    client = get_data_client(creds_path)
    response = client.run_report(req)
    return serialize_report_response(response, dim_names, met_names)


def cmd_realtime(args, property_id, creds_path):
    if not args.metrics:
        print("--metrics / -m is required", file=sys.stderr)
        sys.exit(1)

    dim_names = args.dimensions.split(",") if args.dimensions else []
    met_names = args.metrics.split(",")

    req = RunRealtimeReportRequest(
        property=f"properties/{property_id}",
        dimensions=[Dimension(name=d) for d in dim_names],
        metrics=[Metric(name=m) for m in met_names],
    )

    if args.limit:
        req.limit = args.limit

    client = get_data_client(creds_path)
    response = client.run_realtime_report(req)
    return serialize_report_response(response, dim_names, met_names)


def cmd_accounts(args, creds_path):
    client = get_admin_client(creds_path)
    results = []
    for summary in client.list_account_summaries():
        acct = {
            "account": summary.account,
            "display_name": summary.display_name,
            "properties": [],
        }
        for ps in summary.property_summaries:
            acct["properties"].append({
                "property": ps.property,
                "display_name": ps.display_name,
            })
        results.append(acct)
    return results


def cmd_property(args, property_id, creds_path):
    client = get_admin_client(creds_path)
    prop = client.get_property(name=f"properties/{property_id}")
    return {
        "name": prop.name,
        "display_name": prop.display_name,
        "property_type": prop.property_type.name if prop.property_type else None,
        "industry_category": prop.industry_category.name if prop.industry_category else None,
        "time_zone": prop.time_zone,
        "currency_code": prop.currency_code,
        "create_time": prop.create_time.isoformat() if prop.create_time else None,
        "update_time": prop.update_time.isoformat() if prop.update_time else None,
    }


def cmd_custom_dims(args, property_id, creds_path):
    client = get_admin_client(creds_path)
    results = []
    for cd in client.list_custom_dimensions(parent=f"properties/{property_id}"):
        results.append({
            "parameter_name": cd.parameter_name,
            "display_name": cd.display_name,
            "description": cd.description,
            "scope": cd.scope.name if cd.scope else None,
        })
    return results


def cmd_custom_metrics(args, property_id, creds_path):
    client = get_admin_client(creds_path)
    results = []
    for cm in client.list_custom_metrics(parent=f"properties/{property_id}"):
        results.append({
            "parameter_name": cm.parameter_name,
            "display_name": cm.display_name,
            "description": cm.description,
            "scope": cm.scope.name if cm.scope else None,
            "measurement_unit": cm.measurement_unit.name if cm.measurement_unit else None,
        })
    return results


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="GA4 Data API CLI")
    parser.add_argument("--config", help="Path to ga4-config.yaml")
    parser.add_argument("--property", help="Override property_id from config")
    sub = parser.add_subparsers(dest="command")

    # report
    p_report = sub.add_parser("report", help="Run a standard report")
    p_report.add_argument("-d", "--dimensions", help="Comma-separated dimension names")
    p_report.add_argument("-m", "--metrics", help="Comma-separated metric names")
    p_report.add_argument("--start", help="Start date (YYYY-MM-DD or NdaysAgo, default: 7daysAgo)")
    p_report.add_argument("--end", help="End date (YYYY-MM-DD or yesterday, default: yesterday)")
    p_report.add_argument("--filter", action="append", help="Filter: field==value (repeatable, ANDed)")
    p_report.add_argument("--order-by", help="Order by field (use --desc for descending)")
    p_report.add_argument("--desc", action="store_true", help="Descending order (use with --order-by)")
    p_report.add_argument("--limit", type=int, help="Max rows returned")
    p_report.add_argument("--json", help="Raw JSON request body (overrides other flags)")

    # realtime
    p_rt = sub.add_parser("realtime", help="Run a realtime report")
    p_rt.add_argument("-d", "--dimensions", help="Comma-separated dimension names")
    p_rt.add_argument("-m", "--metrics", help="Comma-separated metric names")
    p_rt.add_argument("--limit", type=int, help="Max rows returned")

    # admin commands
    sub.add_parser("accounts", help="List accounts and properties")
    sub.add_parser("property", help="Current property details")
    sub.add_parser("custom-dims", help="List custom dimensions")
    sub.add_parser("custom-metrics", help="List custom metrics")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    config_path = find_config(args.config)
    property_id, creds_path = load_config(config_path)
    if args.property:
        property_id = args.property

    try:
        if args.command == "report":
            result = cmd_report(args, property_id, creds_path)
        elif args.command == "realtime":
            result = cmd_realtime(args, property_id, creds_path)
        elif args.command == "accounts":
            result = cmd_accounts(args, creds_path)
        elif args.command == "property":
            result = cmd_property(args, property_id, creds_path)
        elif args.command == "custom-dims":
            result = cmd_custom_dims(args, property_id, creds_path)
        elif args.command == "custom-metrics":
            result = cmd_custom_metrics(args, property_id, creds_path)
        else:
            parser.print_help()
            sys.exit(1)

        json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
        print()
    except Exception as e:
        msg = str(e)
        json.dump({"error": msg}, sys.stderr, indent=2, ensure_ascii=False)
        print(file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
