# PlotEngine Billing API Guide

**Base URL:** `https://api.plot-engine.com`
**Frontend URL:** `https://plot-engine.com`

## Overview

PlotEngine uses a **prepaid credits** system for AI usage billing:

- Users purchase credits (minimum $5, any amount)
- Credits are stored as USD balance
- AI usage automatically deducts from credits
- No subscription needed - just one-time purchases

## Pricing

All prices are **per 1 million tokens** and represent 2x the actual AI API cost:

| Model | Input Tokens | Output Tokens |
|-------|--------------|---------------|
| Claude Sonnet 4 | $6.00 | $30.00 |
| Claude Opus 4.5 | $10.00 | $50.00 |
| Claude Haiku 3 | $0.50 | $2.50 |
| GPT-4 Turbo | $20.00 | $60.00 |
| GPT-4o | $10.00 | $30.00 |
| GPT-4o Mini | $0.30 | $1.20 |

**Typical costs:**
- Simple entity extraction (~500 tokens): ~$0.01
- Consistency check (~2,000 tokens): ~$0.05
- Foreshadowing analysis (~5,000 tokens): ~$0.10

---

## API Endpoints

### 1. Get Credits Balance

```http
GET /billing/credits
Authorization: Bearer <token>
```

**Response:**
```json
{
  "creditsBalance": 15.50
}
```

---

### 2. Get Pricing Info (Public)

```http
GET /billing/pricing
```

**Response:**
```json
{
  "pricing": {
    "claude-sonnet-4-20250514": {
      "provider": "anthropic",
      "displayName": "Claude Sonnet 4",
      "inputPricePerMillion": 6.00,
      "outputPricePerMillion": 30.00
    },
    "gpt-4-turbo-preview": {
      "provider": "openai",
      "displayName": "GPT-4 Turbo",
      "inputPricePerMillion": 20.00,
      "outputPricePerMillion": 60.00
    }
    // ... more models
  },
  "minimumPurchase": 5,
  "currency": "USD",
  "note": "Prices are per 1 million tokens. Credits are deducted based on actual usage."
}
```

---

### 3. Get Billing Status

```http
GET /billing/status
Authorization: Bearer <token>
```

**Response:**
```json
{
  "enabled": true,
  "creditsBalance": 15.50,
  "pricing": { /* same as /pricing */ }
}
```

---

### 4. Get Billing Summary

```http
GET /billing/summary
Authorization: Bearer <token>
```

**Response:**
```json
{
  "creditsBalance": 15.50,
  "transactions": [
    {
      "id": "uuid",
      "type": "usage",
      "amount": -0.02,
      "balanceAfter": 15.50,
      "description": "entity_extraction - claude-sonnet-4-20250514",
      "model": "claude-sonnet-4-20250514",
      "inputTokens": 450,
      "outputTokens": 120,
      "createdAt": "2025-11-26T14:30:00Z"
    },
    {
      "id": "uuid",
      "type": "purchase",
      "amount": 10.00,
      "balanceAfter": 15.52,
      "description": "Purchased $10.00 in credits",
      "model": null,
      "inputTokens": null,
      "outputTokens": null,
      "createdAt": "2025-11-26T10:00:00Z"
    }
  ],
  "payments": [
    {
      "id": "uuid",
      "amountUsd": 10.00,
      "status": "paid",
      "paidAt": "2025-11-26T10:00:00Z",
      "createdAt": "2025-11-26T10:00:00Z"
    }
  ],
  "usageStats": [
    {
      "model": "claude-sonnet-4-20250514",
      "requestCount": 25,
      "totalCost": 0.45,
      "totalInputTokens": 12500,
      "totalOutputTokens": 3200
    }
  ]
}
```

---

### 5. Get Transaction History

```http
GET /billing/transactions?limit=50&offset=0
Authorization: Bearer <token>
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| limit | integer | 50 | Max 100 |
| offset | integer | 0 | For pagination |

**Response:**
```json
{
  "transactions": [
    {
      "id": "uuid",
      "type": "usage",
      "amount": -0.02,
      "balanceAfter": 15.50,
      "description": "entity_extraction - claude-sonnet-4-20250514",
      "model": "claude-sonnet-4-20250514",
      "inputTokens": 450,
      "outputTokens": 120,
      "createdAt": "2025-11-26T14:30:00Z"
    }
  ]
}
```

**Transaction Types:**
- `purchase` - Credits purchased (positive amount)
- `usage` - AI usage (negative amount)
- `refund` - Refund (positive amount)
- `bonus` - Promotional credits (positive amount)

---

### 6. Purchase Credits

```http
POST https://api.plot-engine.com/billing/purchase
Authorization: Bearer <token>
Content-Type: application/json

{
  "amount": 10,
  "successUrl": "https://plot-engine.com/billing/success",
  "cancelUrl": "https://plot-engine.com/billing"
}
```

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| amount | number | Yes | Amount in USD (minimum $5) |
| successUrl | string | No | Redirect after successful payment |
| cancelUrl | string | No | Redirect if user cancels |

**Response:**
```json
{
  "sessionId": "cs_test_...",
  "url": "https://checkout.stripe.com/c/pay/cs_test_..."
}
```

**Frontend Flow:**
1. Call `POST /billing/purchase` with desired amount
2. Redirect user to `response.url` (Stripe Checkout)
3. User completes payment on Stripe
4. Stripe redirects to `successUrl`
5. Credits are automatically added via webhook

**Error Responses:**
```json
// Minimum not met
{
  "statusCode": 400,
  "error": "Minimum purchase amount is $5"
}

// Stripe not configured
{
  "statusCode": 503,
  "error": "Billing not configured"
}
```

---

## Frontend Integration Examples

### Dart/Flutter Models

```dart
class BillingStatus {
  final bool enabled;
  final double creditsBalance;
  final Map<String, ModelPricing> pricing;

  BillingStatus.fromJson(Map<String, dynamic> json)
      : enabled = json['enabled'] ?? false,
        creditsBalance = (json['creditsBalance'] ?? 0).toDouble(),
        pricing = (json['pricing'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, ModelPricing.fromJson(v)),
        ) ?? {};
}

class ModelPricing {
  final String provider;
  final String displayName;
  final double inputPricePerMillion;
  final double outputPricePerMillion;

  ModelPricing.fromJson(Map<String, dynamic> json)
      : provider = json['provider'] ?? '',
        displayName = json['displayName'] ?? '',
        inputPricePerMillion = (json['inputPricePerMillion'] ?? 0).toDouble(),
        outputPricePerMillion = (json['outputPricePerMillion'] ?? 0).toDouble();
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String description;
  final String? model;
  final int? inputTokens;
  final int? outputTokens;
  final DateTime createdAt;

  Transaction.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        type = json['type'] ?? '',
        amount = (json['amount'] ?? 0).toDouble(),
        balanceAfter = (json['balanceAfter'] ?? 0).toDouble(),
        description = json['description'] ?? '',
        model = json['model'],
        inputTokens = json['inputTokens'],
        outputTokens = json['outputTokens'],
        createdAt = DateTime.parse(json['createdAt']);
}

class CheckoutSession {
  final String sessionId;
  final String url;

  CheckoutSession.fromJson(Map<String, dynamic> json)
      : sessionId = json['sessionId'] ?? '',
        url = json['url'] ?? '';
}
```

### Purchase Credits Flow (Flutter)

```dart
import 'package:url_launcher/url_launcher.dart';

class BillingService {
  final ApiClient _api;

  Future<double> getCreditsBalance() async {
    final response = await _api.get('/billing/credits');
    return (response['creditsBalance'] ?? 0).toDouble();
  }

  Future<void> purchaseCredits(double amount) async {
    if (amount < 5) {
      throw Exception('Minimum purchase is \$5');
    }

    final response = await _api.post('/billing/purchase', {
      'amount': amount,
      'successUrl': 'https://plot-engine.com/billing/success',
      'cancelUrl': 'https://plot-engine.com/billing',
    });

    final checkoutUrl = response['url'];

    // Open Stripe Checkout in browser
    if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
      await launchUrl(
        Uri.parse(checkoutUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
```

### Display Credits Balance (Flutter)

```dart
class CreditsDisplay extends StatelessWidget {
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: balance > 1 ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: balance > 1 ? Colors.green : Colors.orange,
          ),
          SizedBox(width: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          if (balance < 1)
            TextButton(
              onPressed: () => _showPurchaseDialog(context),
              child: Text('Add Credits'),
            ),
        ],
      ),
    );
  }
}
```

---

---

## Usage Dashboard APIs

These endpoints help display usage statistics and history for the user dashboard.

### 7. Get Usage Summary

```http
GET https://api.plot-engine.com/ai/usage
Authorization: Bearer <token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| days | integer | Filter to last N days (1-365) |
| startDate | date | Filter from date (YYYY-MM-DD) |
| endDate | date | Filter to date (YYYY-MM-DD) |

**Response:**
```json
{
  "creditsBalance": 15.50,
  "summary": [
    {
      "provider": "anthropic",
      "service": "entity_extraction",
      "request_count": "25",
      "total_input_tokens": "12500",
      "total_output_tokens": "3200",
      "total_tokens": "15700"
    },
    {
      "provider": "anthropic",
      "service": "consistency_check",
      "request_count": "10",
      "total_input_tokens": "45000",
      "total_output_tokens": "8500",
      "total_tokens": "53500"
    }
  ],
  "totals": {
    "totalRequests": 35,
    "totalInputTokens": 57500,
    "totalOutputTokens": 11700,
    "totalTokens": 69200
  },
  "recentActivity": [
    {
      "id": "uuid",
      "provider": "anthropic",
      "model": "claude-sonnet-4-20250514",
      "service": "entity_extraction",
      "inputTokens": 450,
      "outputTokens": 120,
      "totalTokens": 570,
      "createdAt": "2025-11-26T14:30:00Z"
    }
  ]
}
```

---

### 8. Get Daily Usage

```http
GET https://api.plot-engine.com/ai/usage/daily?days=30
Authorization: Bearer <token>
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| days | integer | 30 | Number of days (1-365) |

**Response:**
```json
{
  "daily": [
    {
      "date": "2025-11-26",
      "provider": "anthropic",
      "requestCount": 15,
      "inputTokens": 7500,
      "outputTokens": 1800,
      "totalTokens": 9300
    },
    {
      "date": "2025-11-25",
      "provider": "anthropic",
      "requestCount": 20,
      "inputTokens": 10000,
      "outputTokens": 2400,
      "totalTokens": 12400
    },
    {
      "date": "2025-11-25",
      "provider": "openai",
      "requestCount": 5,
      "inputTokens": 2500,
      "outputTokens": 600,
      "totalTokens": 3100
    }
  ]
}
```

---

## Frontend Dashboard Examples

### Dart/Flutter Models for Usage

```dart
class UsageSummary {
  final double? creditsBalance;
  final List<ServiceUsage> summary;
  final UsageTotals totals;
  final List<RecentActivity> recentActivity;

  UsageSummary.fromJson(Map<String, dynamic> json)
      : creditsBalance = json['creditsBalance']?.toDouble(),
        summary = (json['summary'] as List?)
            ?.map((e) => ServiceUsage.fromJson(e))
            .toList() ?? [],
        totals = UsageTotals.fromJson(json['totals'] ?? {}),
        recentActivity = (json['recentActivity'] as List?)
            ?.map((e) => RecentActivity.fromJson(e))
            .toList() ?? [];
}

class ServiceUsage {
  final String provider;
  final String service;
  final int requestCount;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalTokens;

  ServiceUsage.fromJson(Map<String, dynamic> json)
      : provider = json['provider'] ?? '',
        service = json['service'] ?? '',
        requestCount = int.tryParse(json['request_count']?.toString() ?? '0') ?? 0,
        totalInputTokens = int.tryParse(json['total_input_tokens']?.toString() ?? '0') ?? 0,
        totalOutputTokens = int.tryParse(json['total_output_tokens']?.toString() ?? '0') ?? 0,
        totalTokens = int.tryParse(json['total_tokens']?.toString() ?? '0') ?? 0;
}

class UsageTotals {
  final int totalRequests;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalTokens;

  UsageTotals.fromJson(Map<String, dynamic> json)
      : totalRequests = json['totalRequests'] ?? 0,
        totalInputTokens = json['totalInputTokens'] ?? 0,
        totalOutputTokens = json['totalOutputTokens'] ?? 0,
        totalTokens = json['totalTokens'] ?? 0;
}

class RecentActivity {
  final String id;
  final String provider;
  final String model;
  final String service;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final DateTime createdAt;

  RecentActivity.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        provider = json['provider'] ?? '',
        model = json['model'] ?? '',
        service = json['service'] ?? '',
        inputTokens = json['inputTokens'] ?? 0,
        outputTokens = json['outputTokens'] ?? 0,
        totalTokens = json['totalTokens'] ?? 0,
        createdAt = DateTime.parse(json['createdAt']);
}

class DailyUsage {
  final String date;
  final String provider;
  final int requestCount;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  DailyUsage.fromJson(Map<String, dynamic> json)
      : date = json['date'] ?? '',
        provider = json['provider'] ?? '',
        requestCount = json['requestCount'] ?? 0,
        inputTokens = json['inputTokens'] ?? 0,
        outputTokens = json['outputTokens'] ?? 0,
        totalTokens = json['totalTokens'] ?? 0;
}
```

### Usage Dashboard Widget (Flutter)

```dart
class UsageDashboard extends StatefulWidget {
  @override
  _UsageDashboardState createState() => _UsageDashboardState();
}

class _UsageDashboardState extends State<UsageDashboard> {
  UsageSummary? _usage;
  List<DailyUsage>? _dailyUsage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    setState(() => _loading = true);
    try {
      final usage = await _api.get('/ai/usage?days=30');
      final daily = await _api.get('/ai/usage/daily?days=30');
      setState(() {
        _usage = UsageSummary.fromJson(usage);
        _dailyUsage = (daily['daily'] as List)
            .map((e) => DailyUsage.fromJson(e))
            .toList();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Credits Balance Card
        _buildBalanceCard(),

        SizedBox(height: 24),

        // Usage Stats Cards
        _buildStatsRow(),

        SizedBox(height: 24),

        // Usage by Service
        Text('Usage by Service', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 12),
        _buildServiceUsageList(),

        SizedBox(height: 24),

        // Recent Activity
        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 12),
        _buildRecentActivityList(),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final balance = _usage?.creditsBalance ?? 0;
    return Card(
      color: balance > 1 ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet, size: 40),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Credits Balance', style: TextStyle(color: Colors.grey)),
                Text(
                  '\$${balance.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () => _showPurchaseDialog(),
              child: Text('Add Credits'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final totals = _usage?.totals;
    return Row(
      children: [
        _buildStatCard('Total Requests', '${totals?.totalRequests ?? 0}', Icons.send),
        SizedBox(width: 16),
        _buildStatCard('Input Tokens', _formatTokens(totals?.totalInputTokens ?? 0), Icons.input),
        SizedBox(width: 16),
        _buildStatCard('Output Tokens', _formatTokens(totals?.totalOutputTokens ?? 0), Icons.output),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue),
              SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceUsageList() {
    return Column(
      children: (_usage?.summary ?? []).map((s) => ListTile(
        leading: CircleAvatar(
          child: Text(s.service[0].toUpperCase()),
        ),
        title: Text(_formatServiceName(s.service)),
        subtitle: Text('${s.requestCount} requests'),
        trailing: Text('${_formatTokens(s.totalTokens)} tokens'),
      )).toList(),
    );
  }

  Widget _buildRecentActivityList() {
    return Column(
      children: (_usage?.recentActivity ?? []).take(10).map((a) => ListTile(
        leading: Icon(Icons.api),
        title: Text(_formatServiceName(a.service)),
        subtitle: Text(a.model),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${a.totalTokens} tokens'),
            Text(
              _formatTimeAgo(a.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      )).toList(),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) return '${(tokens / 1000000).toStringAsFixed(1)}M';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return tokens.toString();
  }

  String _formatServiceName(String service) {
    return service.replaceAll('_', ' ').split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
```

### Usage Chart (with fl_chart package)

```dart
// Add to pubspec.yaml: fl_chart: ^0.66.0

import 'package:fl_chart/fl_chart.dart';

class UsageChart extends StatelessWidget {
  final List<DailyUsage> dailyUsage;

  Widget build(BuildContext context) {
    // Group by date and sum tokens
    final Map<String, int> tokensByDate = {};
    for (final usage in dailyUsage) {
      tokensByDate[usage.date] = (tokensByDate[usage.date] ?? 0) + usage.totalTokens;
    }

    final sortedDates = tokensByDate.keys.toList()..sort();
    final last7Days = sortedDates.reversed.take(7).toList().reversed.toList();

    return Container(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: last7Days.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (tokensByDate[entry.value] ?? 0) / 1000, // Show in K
                  color: Colors.blue,
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = last7Days[value.toInt()];
                  return Text(date.substring(5)); // MM-DD
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}K'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Handling Insufficient Credits

When a user runs out of credits, AI API calls will still work but credits will go negative. You may want to:

1. **Check balance before AI calls:**
```dart
final balance = await billingService.getCreditsBalance();
if (balance < 0.01) {
  // Show "Add credits" prompt
  return;
}
// Proceed with AI call
```

2. **Show low balance warning:**
```dart
if (balance < 1.0) {
  showSnackBar('Low credits balance. Consider adding more.');
}
```

3. **Block usage at 0 credits** (optional - backend can be configured for this)

---

## Webhook Events (Backend Reference)

The backend automatically handles these Stripe events:

| Event | Action |
|-------|--------|
| `checkout.session.completed` | Add credits to user balance |
| `payment_intent.succeeded` | Log successful payment |
| `payment_intent.payment_failed` | Log failed payment |

No frontend action needed - credits are added automatically after successful payment.

---

## Testing

Use Stripe test mode for development:

**Test Card Numbers:**
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`
- Requires auth: `4000 0025 0000 3155`

Use any future expiry date and any 3-digit CVC.
