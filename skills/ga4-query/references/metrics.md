# GA4 Metrics Reference

Curated list of commonly used GA4 metrics. For the full list, see
[Google Analytics Dimensions & Metrics Explorer](https://ga-dev-tools.google/ga4/dimensions-metrics-explorer/).

## Users

| Metric | Description |
|--------|-------------|
| `activeUsers` | Users with an engaged session or first_visit/first_open event |
| `newUsers` | First-time users |
| `totalUsers` | Total unique users |
| `dauPerMau` | Daily active users / monthly active users |
| `dauPerWau` | Daily active users / weekly active users |
| `wauPerMau` | Weekly active users / monthly active users |

## Sessions

| Metric | Description |
|--------|-------------|
| `sessions` | Total sessions |
| `sessionsPerUser` | Average sessions per user |
| `engagedSessions` | Sessions lasting >10s, with key event, or 2+ page views |
| `engagementRate` | Engaged sessions / total sessions |
| `bounceRate` | 1 - engagementRate |
| `averageSessionDuration` | Average session duration in seconds |
| `sessionConversionRate` | Sessions with at least one conversion / total sessions |

## Engagement

| Metric | Description |
|--------|-------------|
| `screenPageViews` | Total page/screen views |
| `screenPageViewsPerSession` | Page views per session |
| `screenPageViewsPerUser` | Page views per user |
| `userEngagementDuration` | Total engagement time in seconds |
| `engagedSessions` | Sessions exceeding engagement threshold |
| `eventCount` | Total event count |
| `eventCountPerUser` | Events per user |
| `eventsPerSession` | Events per session |

## Key Events (Conversions)

| Metric | Description |
|--------|-------------|
| `conversions` | Total key event conversions |
| `sessionConversionRate` | Conversion rate per session |
| `userConversionRate` | Conversion rate per user |

## Revenue (e-commerce)

| Metric | Description |
|--------|-------------|
| `totalRevenue` | Total revenue (purchases + subscriptions + ads) |
| `purchaseRevenue` | Revenue from purchases only |
| `ecommercePurchases` | Number of purchases |
| `transactions` | Transaction count |
| `transactionsPerPurchaser` | Transactions per purchasing user |
| `averagePurchaseRevenue` | Average revenue per transaction |
| `averageRevenuePerUser` | ARPU |
| `totalAdRevenue` | Ad revenue |

## Google Ads

| Metric | Description |
|--------|-------------|
| `advertiserAdClicks` | Clicks from Google Ads |
| `advertiserAdCost` | Cost from Google Ads |
| `advertiserAdCostPerClick` | CPC from Google Ads |
| `advertiserAdImpressions` | Impressions from Google Ads |
| `returnOnAdSpend` | ROAS from Google Ads |

## Realtime-only Metrics

| Metric | Description |
|--------|-------------|
| `activeUsers` | Currently active users |
| `screenPageViews` | Page views in last 30 min |
| `eventCount` | Events in last 30 min |
| `conversions` | Conversions in last 30 min |
