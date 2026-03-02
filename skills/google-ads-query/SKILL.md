---
name: google-ads-query
description: "Query any Google Ads account via GAQL. Use when the user asks about Google Ads campaigns, conversions, keywords, ad performance, or bidding. Triggered by: Google Ads, campaign, conversion, PPC, CPC, keyword, click, impression, ROAS, CPA."
---

# Google Ads Query

## Setup

Check prerequisites before querying:

**Script path resolution:** Before running any script, determine the correct base path. Check in this order:
1. `.claude/skills/google-ads-query/scripts/` — project-local install (run from repository root)
2. `~/.claude/skills/google-ads-query/scripts/` — global install

Use whichever path exists. All script paths below use the project-local form; substitute the global path if that's where scripts are found.

1. **Virtual environment**: `.claude/skills/google-ads-query/scripts/.venv/` must exist
2. **Config file**: `google-ads.yaml` must be findable (see Config section)

### First-time setup

```bash
# 1. Install dependencies
bash .claude/skills/google-ads-query/scripts/setup.sh

# 2. Create google-ads.yaml in project root or ~/.config/google-ads-query/
#    (see Config section for template)

# 3. Test
gads "SELECT customer.id FROM customer"
```

## Config

The script searches for `google-ads.yaml` in this order:

1. `--config` CLI parameter (explicit path)
2. `./google-ads.yaml` (project root)
3. `~/.config/google-ads-query/google-ads.yaml` (user-level)

Template (`google-ads.yaml`):
```yaml
# Service account authentication:
developer_token: "YOUR_TOKEN"
json_key_file_path: "/path/to/service-account.json"
customer_id: "YOUR_CUSTOMER_ID"
use_proto_plus: true

# OR OAuth2 authentication:
# developer_token: "YOUR_TOKEN"
# client_id: "YOUR_CLIENT_ID.apps.googleusercontent.com"
# client_secret: "YOUR_SECRET"
# refresh_token: "1//YOUR_REFRESH_TOKEN"
# customer_id: "YOUR_CUSTOMER_ID"
# use_proto_plus: true

# Optional (manager accounts):
# login_customer_id: "MANAGER_CUSTOMER_ID"
```

## Usage

Use the `gads` alias for queries:

```bash
alias gads='.claude/skills/google-ads-query/scripts/.venv/bin/python3 .claude/skills/google-ads-query/scripts/query.py'
```

```bash
# Basic query (customer ID from config)
gads "SELECT campaign.name, metrics.clicks FROM campaign"

# Pipe query via stdin (recommended — avoids shell escaping issues with single quotes)
echo "SELECT campaign.name FROM campaign WHERE campaign.status != 'REMOVED'" | gads -

# Override customer ID
gads --customer-id 9876543210 "SELECT ..."

# Explicit config path
gads --config /path/to/google-ads.yaml "SELECT ..."
```

**Stdin mode:** Pass `-` as the query argument to read from stdin. This is the recommended approach for queries containing single quotes (e.g., `WHERE campaign.status != 'REMOVED'`), as it bypasses shell argument escaping entirely.

**Output:** JSON array to stdout. Enums returned as names (e.g., `"ENABLED"`, not `2`).
**Errors:** JSON to stderr + exit code 1.

## Field Notes

These fields may cause issues depending on API version:

- `campaign.start_date`, `campaign.end_date` — may be unrecognized
- `conversion_action.type` — can return cryptic errors
- `conversion_action.tag_snippets` — repeated composite, may fail in some versions

The script handles repeated fields (both scalar and composite) correctly via protobuf serialization. If a query fails, remove suspected fields one at a time to isolate the issue.

## Query Patterns

### Campaign overview
```
SELECT campaign.id, campaign.name, campaign.status,
  campaign.advertising_channel_type, campaign.bidding_strategy_type,
  metrics.impressions, metrics.clicks, metrics.cost_micros,
  metrics.conversions, metrics.all_conversions
FROM campaign
WHERE campaign.status != 'REMOVED'
```

### Conversion actions (full list)
```
SELECT conversion_action.id, conversion_action.name,
  conversion_action.status, conversion_action.category,
  conversion_action.origin, conversion_action.counting_type,
  conversion_action.include_in_conversions_metric,
  conversion_action.primary_for_goal
FROM conversion_action
```

### Campaign conversion goals
```
SELECT campaign.id, campaign.name,
  campaign_conversion_goal.category, campaign_conversion_goal.origin,
  campaign_conversion_goal.biddable
FROM campaign_conversion_goal
WHERE campaign.id = CAMPAIGN_ID
```

### Conversion goal config (account vs campaign level)
```
SELECT campaign.id, campaign.name,
  conversion_goal_campaign_config.goal_config_level
FROM conversion_goal_campaign_config
```

### Metrics with date range
```
SELECT campaign.name, metrics.impressions, metrics.clicks,
  metrics.cost_micros, metrics.conversions, segments.date
FROM campaign
WHERE segments.date >= 'YYYY-MM-DD' AND segments.date <= 'YYYY-MM-DD'
  AND campaign.status != 'REMOVED'
```

### Ad group details
```
SELECT ad_group.id, ad_group.name, ad_group.status,
  ad_group.cpc_bid_micros, campaign.name
FROM ad_group
WHERE campaign.status != 'REMOVED'
```

### Keywords
```
SELECT ad_group_criterion.keyword.text,
  ad_group_criterion.keyword.match_type,
  ad_group_criterion.status, metrics.clicks,
  metrics.impressions, metrics.cost_micros
FROM keyword_view
WHERE campaign.status != 'REMOVED'
```

### Search terms report
```
SELECT search_term_view.search_term, metrics.clicks,
  metrics.impressions, metrics.cost_micros, metrics.conversions
FROM search_term_view
WHERE segments.date >= 'YYYY-MM-DD' AND segments.date <= 'YYYY-MM-DD'
```

## Enum Reference

The script returns enum values as human-readable names (e.g., `"ENABLED"`, `"MAXIMIZE_CONVERSIONS"`), so you typically don't need to decode numeric codes. For raw numeric references, see [references/enums.md](references/enums.md).

Key enum values for GAQL WHERE clauses (these use string names):

| Field | WHERE value | Meaning |
|-------|-------------|---------|
| campaign.status | `'ENABLED'` | Active campaign |
| campaign.status | `'PAUSED'` | Paused campaign |
| campaign.status | `'REMOVED'` | Deleted campaign |

## Conversion Tracking Audit

1. Query customer settings — confirm `conversion_tracking_status` and `auto_tagging_enabled`
2. Query all `conversion_action` — list actions, check status, primary_for_goal, include_in_conversions_metric
3. Query `campaign_conversion_goal` for the campaign — verify biddable goals match campaign objective
4. Query `conversion_goal_campaign_config` — check if campaign uses campaign-level or account-level goals
5. If GA4-imported conversions: verify GA4 tag fires on target pages (recommend Google Tag Assistant)
6. Check metrics: compare `metrics.conversions` (primary only) vs `metrics.all_conversions` (includes secondary)

## Notes

- `metrics.cost_micros` is in micros (divide by 1,000,000 for currency)
- GAQL WHERE uses string enum values (`'REMOVED'`), not numeric codes
- `segments.date` requires both `>=` and `<=` bounds
- Campaign-level goals override account-level defaults when `goal_config_level` = CAMPAIGN
