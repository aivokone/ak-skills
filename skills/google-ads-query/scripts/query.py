#!/usr/bin/env python3
"""Query Google Ads via GAQL. Lightweight CLI replacement for google-ads-mcp."""

import argparse
import json
import sys
from pathlib import Path

import yaml
from google.ads.googleads.client import GoogleAdsClient
from google.ads.googleads.errors import GoogleAdsException


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

DEFAULT_CONFIG_LOCATIONS = [
    Path("./google-ads.yaml"),
    Path.home() / ".config" / "google-ads-query" / "google-ads.yaml",
]

SETUP_MESSAGE = """\
Google Ads config not found.

Searched:
  1. ./google-ads.yaml
  2. ~/.config/google-ads-query/google-ads.yaml

Create google-ads.yaml with your credentials:

  # Service account:
  developer_token: "YOUR_TOKEN"
  json_key_file_path: "/path/to/service-account.json"
  customer_id: "YOUR_CUSTOMER_ID"
  use_proto_plus: true

  # OAuth2:
  developer_token: "YOUR_TOKEN"
  client_id: "YOUR_CLIENT_ID.apps.googleusercontent.com"
  client_secret: "YOUR_SECRET"
  refresh_token: "1//YOUR_REFRESH_TOKEN"
  customer_id: "YOUR_CUSTOMER_ID"
  use_proto_plus: true

Place it in your project root or ~/.config/google-ads-query/
"""


def find_config(explicit_path: str | None = None) -> Path:
    """Locate google-ads.yaml using the search hierarchy."""
    if explicit_path:
        p = Path(explicit_path)
        if p.is_file():
            return p
        print(f"Error: config not found at {explicit_path}", file=sys.stderr)
        sys.exit(1)

    for loc in DEFAULT_CONFIG_LOCATIONS:
        if loc.is_file():
            return loc

    print(SETUP_MESSAGE, file=sys.stderr)
    sys.exit(1)


def load_config(path: Path) -> tuple[GoogleAdsClient, str]:
    """Load GoogleAdsClient and default customer_id from config."""
    with open(path) as f:
        raw = yaml.safe_load(f)

    if not isinstance(raw, dict):
        print("Error: google-ads.yaml is empty or invalid", file=sys.stderr)
        sys.exit(1)

    customer_id = str(raw.get("customer_id", "")).replace("-", "")
    if not customer_id:
        print("Error: customer_id missing from config", file=sys.stderr)
        sys.exit(1)

    client = GoogleAdsClient.load_from_storage(str(path))
    return client, customer_id


# ---------------------------------------------------------------------------
# Protobuf serialization (proto-plus aware)
# ---------------------------------------------------------------------------

def _is_enum(value) -> bool:
    """Check if value is a proto-plus or Python enum."""
    return hasattr(value, "name") and isinstance(value, int)


def serialize_value(value):
    """Convert proto-plus / protobuf values to JSON-safe Python types.

    Proto-plus with use_proto_plus=True wraps values in Python-native types:
    - Enums become IntEnum subclasses (isinstance(v, int) is True, but v.name exists)
    - Repeated fields become list-like containers
    - Messages become proto.Message subclasses
    """
    # Enum check MUST come before int check (enums are IntEnum subclasses)
    if _is_enum(value):
        return value.name

    # Primitives (after enum check)
    if isinstance(value, (bool, int, float, str, bytes)):
        return value

    # Repeated fields (proto-plus RepeatedComposite / list-like)
    type_name = type(value).__name__
    if type_name in ("RepeatedComposite", "RepeatedCompositeFieldContainer",
                     "RepeatedScalarFieldContainer"):
        return [serialize_value(v) for v in value]
    if isinstance(value, (list, tuple)):
        return [serialize_value(v) for v in value]

    # MapComposite (proto-plus map fields)
    if type_name == "MapComposite":
        return {k: serialize_value(v) for k, v in value.items()}

    # Proto-plus Message → serialize populated fields via proto-plus accessors
    if hasattr(value, "_pb") and hasattr(value._pb, "ListFields"):
        return _serialize_proto_plus_message(value)

    # Raw protobuf Message
    if hasattr(value, "DESCRIPTOR") and hasattr(value, "ListFields"):
        result = {}
        for fd, fv in value.ListFields():
            result[fd.name] = serialize_value(fv)
        return result

    # Fallback
    return str(value)


def _serialize_proto_plus_message(msg) -> dict:
    """Serialize a proto-plus Message using its wrapper layer to preserve enums."""
    result = {}
    # Use _pb.ListFields() to find which fields are populated,
    # then access via proto-plus wrapper to get proper enum types
    for fd, _raw_val in msg._pb.ListFields():
        name = fd.name
        wrapper_val = getattr(msg, name, None)
        if wrapper_val is not None:
            result[name] = serialize_value(wrapper_val)
    return result


def serialize_row(row) -> dict:
    """Serialize a single GoogleAdsRow to a plain dict."""
    result = {}
    # row._pb.ListFields() tells us which top-level resources are populated
    for fd, _raw_val in row._pb.ListFields():
        resource_name = fd.name
        resource = getattr(row, resource_name, None)
        if resource is not None:
            result[resource_name] = serialize_value(resource)
    return result


# ---------------------------------------------------------------------------
# Query execution
# ---------------------------------------------------------------------------

def execute_query(client: GoogleAdsClient, query: str, customer_id: str) -> list[dict]:
    """Run a GAQL query via search_stream and return serialized results."""
    service = client.get_service("GoogleAdsService")
    stream = service.search_stream(customer_id=customer_id, query=query)

    results = []
    for batch in stream:
        for row in batch.results:
            results.append(serialize_row(row))
    return results


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Query Google Ads via GAQL",
        usage='gads "SELECT campaign.name FROM campaign"',
    )
    parser.add_argument("query", help="GAQL query string")
    parser.add_argument("--customer-id", help="Override customer ID from config")
    parser.add_argument("--config", help="Explicit path to google-ads.yaml")
    args = parser.parse_args()

    # Support stdin: pass "-" as query to read from pipe (avoids shell escaping)
    query = sys.stdin.read().strip() if args.query == "-" else args.query

    config_path = find_config(args.config)
    client, default_cid = load_config(config_path)

    customer_id = (args.customer_id or default_cid).replace("-", "")

    try:
        results = execute_query(client, query, customer_id)
        json.dump(results, sys.stdout, indent=2, ensure_ascii=False)
        print()  # trailing newline
    except GoogleAdsException as ex:
        errors = [e.message for e in ex.failure.errors]
        print(json.dumps({"error": "GoogleAdsException", "details": errors}, indent=2, ensure_ascii=False), file=sys.stderr)
        sys.exit(1)
    except Exception as exc:
        print(json.dumps({"error": str(exc)}, ensure_ascii=False), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
