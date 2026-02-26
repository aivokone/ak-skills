# GA4 Dimensions Reference

Curated list of commonly used GA4 dimensions. For the full list, see
[Google Analytics Dimensions & Metrics Explorer](https://ga-dev-tools.google/ga4/dimensions-metrics-explorer/).

## Time

| Dimension | Description | Format |
|-----------|-------------|--------|
| `date` | Date | YYYYMMDD |
| `dateHour` | Date + hour | YYYYMMDDHH |
| `dateHourMinute` | Date + hour + minute | YYYYMMDDHHMI |
| `dayOfWeek` | Day of week | 0 (Sun) – 6 (Sat) |
| `hour` | Hour of day | 00–23 |
| `month` | Month | MM |
| `year` | Year | YYYY |
| `yearMonth` | Year + month | YYYYMM |
| `yearWeek` | Year + ISO week | YYYYWW |
| `firstSessionDate` | User's first session date | YYYYMMDD |

## Content / Pages

| Dimension | Description |
|-----------|-------------|
| `pagePath` | Page URL path (e.g., `/palvelut/hallitusarviointi`) |
| `pageTitle` | HTML page title |
| `pagePathPlusQueryString` | Path + query string |
| `landingPage` | First page of session |
| `contentGroup` | Content group (if configured) |
| `hostName` | Domain name |
| `unifiedPageScreen` | Page path or screen class |

## Traffic / Attribution

| Dimension | Description |
|-----------|-------------|
| `sessionSource` | Session traffic source (google, direct, ...) |
| `sessionMedium` | Session medium (organic, cpc, referral, ...) |
| `sessionCampaignName` | Campaign name |
| `sessionSourceMedium` | Combined source / medium |
| `sessionDefaultChannelGroup` | Default channel grouping |
| `sessionGoogleAdsAdGroupName` | Google Ads ad group name |
| `sessionGoogleAdsCampaignName` | Google Ads campaign name |
| `sessionGoogleAdsKeyword` | Google Ads keyword text |
| `firstUserSource` | Source of first visit |
| `firstUserMedium` | Medium of first visit |
| `firstUserCampaignName` | Campaign of first visit |

## User

| Dimension | Description |
|-----------|-------------|
| `country` | User country |
| `city` | User city |
| `language` | Browser language |
| `newVsReturning` | `new` or `returning` |
| `userAgeBracket` | Age range (if available) |
| `userGender` | Gender (if available) |

## Technology

| Dimension | Description |
|-----------|-------------|
| `deviceCategory` | `desktop`, `mobile`, or `tablet` |
| `operatingSystem` | OS name |
| `browser` | Browser name |
| `screenResolution` | Screen resolution |
| `platform` | `web`, `ios`, `android` |

## Events

| Dimension | Description |
|-----------|-------------|
| `eventName` | Event name (e.g., `page_view`, `click`) |
| `isKeyEvent` | Whether the event is a key event (`true`/`false`) |
| `customEvent:parameter` | Custom event parameter (requires custom dimension) |

## Google Ads (requires linked account)

| Dimension | Description |
|-----------|-------------|
| `sessionGoogleAdsAdGroupId` | Ad group ID |
| `sessionGoogleAdsAdNetworkType` | Network type |
| `sessionGoogleAdsCampaignId` | Campaign ID |
| `sessionGoogleAdsQuery` | Search query (limited) |

## Realtime-only Dimensions

| Dimension | Description |
|-----------|-------------|
| `unifiedScreenName` | Active screen/page |
| `audienceName` | Audience name |
| `minutesAgo` | Minutes since event (0–29) |
