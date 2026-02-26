# Google Ads Enum Code Mappings

Reference for numeric enum codes returned by the Google Ads API. The query script
returns enum names directly (e.g., "ENABLED"), so this table is a backup reference
for interpreting raw API responses or GAQL WHERE clauses.

Note: Enum codes may vary between API versions. If observed values
don't match this table, cross-reference with the Google Ads API docs.

## Table of Contents

- [Campaign Status](#campaign-status)
- [Ad Group Status](#ad-group-status)
- [Advertising Channel Type](#advertising-channel-type)
- [Bidding Strategy Type](#bidding-strategy-type)
- [Conversion Action Status](#conversion-action-status)
- [Conversion Action Category](#conversion-action-category)
- [Conversion Action Origin](#conversion-action-origin)
- [Conversion Counting Type](#conversion-counting-type)
- [Conversion Tracking Status](#conversion-tracking-status)
- [Goal Config Level](#goal-config-level)
- [Campaign Serving Status](#campaign-serving-status)
- [Keyword Match Type](#keyword-match-type)
- [Ad Type](#ad-type)

## Campaign Status

| Code | Name |
|------|------|
| 0 | UNSPECIFIED |
| 1 | UNKNOWN |
| 2 | ENABLED |
| 3 | PAUSED |
| 4 | REMOVED |

## Ad Group Status

| Code | Name |
|------|------|
| 0 | UNSPECIFIED |
| 1 | UNKNOWN |
| 2 | ENABLED |
| 3 | PAUSED |
| 4 | REMOVED |

## Advertising Channel Type

| Code | Name |
|------|------|
| 2 | SEARCH |
| 3 | DISPLAY |
| 6 | SHOPPING |
| 7 | HOTEL |
| 8 | VIDEO |
| 10 | MULTI_CHANNEL |
| 11 | LOCAL |
| 12 | SMART |
| 13 | PERFORMANCE_MAX |
| 15 | DEMAND_GEN |
| 16 | TRAVEL |

## Bidding Strategy Type

| Code | Name |
|------|------|
| 2 | MANUAL_CPC |
| 3 | MANUAL_CPM |
| 4 | MANUAL_CPV |
| 6 | MAXIMIZE_CLICKS |
| 9 | MAXIMIZE_CONVERSIONS |
| 10 | MAXIMIZE_CONVERSION_VALUE |
| 11 | TARGET_CPA |
| 12 | TARGET_IMPRESSION_SHARE |
| 13 | TARGET_ROAS |
| 14 | TARGET_SPEND |

## Conversion Action Status

| Code | Name |
|------|------|
| 0 | UNSPECIFIED |
| 1 | UNKNOWN |
| 2 | ENABLED |
| 3 | REMOVED |
| 4 | HIDDEN |

## Conversion Action Category

| Code | Name |
|------|------|
| 0 | UNSPECIFIED |
| 1 | DEFAULT |
| 2 | PAGE_VIEW |
| 3 | PURCHASE |
| 4 | SIGNUP |
| 5 | LEAD |
| 7 | DOWNLOAD |
| 9 | ADD_TO_CART |
| 10 | BEGIN_CHECKOUT |
| 11 | SUBSCRIBE_PAID |
| 12 | PHONE_CALL_LEAD |
| 13 | IMPORTED_LEAD |
| 14 | SUBMIT_LEAD_FORM |
| 15 | BOOK_APPOINTMENT |
| 16 | REQUEST_QUOTE |
| 17 | GET_DIRECTIONS |
| 18 | OUTBOUND_CLICK |
| 19 | CONTACT |
| 25 | STORE_VISIT |
| 27 | STORE_SALE |
| 28 | QUALIFIED_LEAD |
| 29 | CONVERTED_LEAD |

## Conversion Action Origin

| Code | Name |
|------|------|
| 0 | UNSPECIFIED |
| 1 | UNKNOWN |
| 2 | WEBSITE |
| 3 | GOOGLE_HOSTED |
| 5 | APP |
| 7 | CALL_FROM_ADS |
| 8 | STORE |
| 9 | YOUTUBE_HOSTED |

## Conversion Counting Type

| Code | Name |
|------|------|
| 0 | UNSPECIFIED |
| 1 | ONE_PER_CLICK |
| 2 | MANY_PER_CLICK |

## Conversion Tracking Status

| Code | Name |
|------|------|
| 0 | UNSPECIFIED |
| 1 | NOT_CONVERSION_TRACKED |
| 2 | CONVERSION_TRACKING_MANAGED_BY_SELF |
| 3 | CONVERSION_TRACKING_MANAGED_BY_THIS_MANAGER |

## Goal Config Level

| Code | Name |
|------|------|
| 0 | UNSPECIFIED |
| 2 | CUSTOMER (account-level defaults) |
| 3 | CAMPAIGN (campaign-level override) |

## Campaign Serving Status

| Code | Name |
|------|------|
| 0 | UNSPECIFIED |
| 2 | SERVING |
| 3 | NONE |
| 4 | ENDED |
| 5 | PENDING |
| 6 | SUSPENDED |

## Keyword Match Type

| Code | Name |
|------|------|
| 2 | EXACT |
| 3 | PHRASE |
| 4 | BROAD |

## Ad Type

| Code | Name |
|------|------|
| 2 | TEXT_AD |
| 3 | EXPANDED_TEXT_AD |
| 6 | RESPONSIVE_SEARCH_AD |
| 7 | IMAGE_AD |
| 12 | VIDEO_AD |
| 15 | RESPONSIVE_DISPLAY_AD |
