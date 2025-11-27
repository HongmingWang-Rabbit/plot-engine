/// Billing status response from /billing/status
class BillingStatus {
  final bool enabled;
  final double creditsBalance;
  final Map<String, ModelPricing> pricing;

  BillingStatus({
    required this.enabled,
    required this.creditsBalance,
    required this.pricing,
  });

  factory BillingStatus.fromJson(Map<String, dynamic> json) {
    final pricingMap = <String, ModelPricing>{};
    final pricingJson = json['pricing'] as Map<String, dynamic>?;
    if (pricingJson != null) {
      pricingJson.forEach((key, value) {
        pricingMap[key] = ModelPricing.fromJson(value as Map<String, dynamic>);
      });
    }

    return BillingStatus(
      enabled: json['enabled'] as bool? ?? false,
      creditsBalance: (json['creditsBalance'] as num?)?.toDouble() ?? 0.0,
      pricing: pricingMap,
    );
  }
}

/// Model pricing information
class ModelPricing {
  final String provider;
  final String displayName;
  final double inputPricePerMillion;
  final double outputPricePerMillion;

  ModelPricing({
    required this.provider,
    required this.displayName,
    required this.inputPricePerMillion,
    required this.outputPricePerMillion,
  });

  factory ModelPricing.fromJson(Map<String, dynamic> json) {
    return ModelPricing(
      provider: json['provider'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      inputPricePerMillion: (json['inputPricePerMillion'] as num?)?.toDouble() ?? 0.0,
      outputPricePerMillion: (json['outputPricePerMillion'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Transaction record
class Transaction {
  final String id;
  final String type; // 'purchase', 'usage', 'refund', 'bonus'
  final double amount;
  final double balanceAfter;
  final String description;
  final String? model;
  final int? inputTokens;
  final int? outputTokens;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    this.model,
    this.inputTokens,
    this.outputTokens,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      model: json['model'] as String?,
      inputTokens: json['inputTokens'] as int?,
      outputTokens: json['outputTokens'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isPurchase => type == 'purchase';
  bool get isUsage => type == 'usage';
  bool get isRefund => type == 'refund';
  bool get isBonus => type == 'bonus';
}

/// Payment record
class Payment {
  final String id;
  final double amountUsd;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.amountUsd,
    required this.status,
    this.paidAt,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String? ?? '',
      amountUsd: (json['amountUsd'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Usage stats by model
class UsageStats {
  final String model;
  final int requestCount;
  final double totalCost;
  final int totalInputTokens;
  final int totalOutputTokens;

  UsageStats({
    required this.model,
    required this.requestCount,
    required this.totalCost,
    required this.totalInputTokens,
    required this.totalOutputTokens,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      model: json['model'] as String? ?? '',
      requestCount: json['requestCount'] as int? ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      totalInputTokens: json['totalInputTokens'] as int? ?? 0,
      totalOutputTokens: json['totalOutputTokens'] as int? ?? 0,
    );
  }
}

/// Billing summary response
class BillingSummary {
  final double creditsBalance;
  final List<Transaction> transactions;
  final List<Payment> payments;
  final List<UsageStats> usageStats;

  BillingSummary({
    required this.creditsBalance,
    required this.transactions,
    required this.payments,
    required this.usageStats,
  });

  factory BillingSummary.fromJson(Map<String, dynamic> json) {
    return BillingSummary(
      creditsBalance: (json['creditsBalance'] as num?)?.toDouble() ?? 0.0,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      usageStats: (json['usageStats'] as List<dynamic>?)
              ?.map((e) => UsageStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Checkout session response
class CheckoutSession {
  final String sessionId;
  final String url;

  CheckoutSession({
    required this.sessionId,
    required this.url,
  });

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    return CheckoutSession(
      sessionId: json['sessionId'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}

/// Usage summary response from /ai/usage
class UsageSummary {
  final double? creditsBalance;
  final List<ServiceUsage> summary;
  final UsageTotals totals;
  final List<RecentActivity> recentActivity;

  UsageSummary({
    this.creditsBalance,
    required this.summary,
    required this.totals,
    required this.recentActivity,
  });

  factory UsageSummary.fromJson(Map<String, dynamic> json) {
    return UsageSummary(
      creditsBalance: (json['creditsBalance'] as num?)?.toDouble(),
      summary: (json['summary'] as List<dynamic>?)
              ?.map((e) => ServiceUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totals: UsageTotals.fromJson(json['totals'] as Map<String, dynamic>? ?? {}),
      recentActivity: (json['recentActivity'] as List<dynamic>?)
              ?.map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Service usage breakdown
class ServiceUsage {
  final String provider;
  final String service;
  final int requestCount;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalTokens;

  ServiceUsage({
    required this.provider,
    required this.service,
    required this.requestCount,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalTokens,
  });

  factory ServiceUsage.fromJson(Map<String, dynamic> json) {
    return ServiceUsage(
      provider: json['provider'] as String? ?? '',
      service: json['service'] as String? ?? '',
      requestCount: int.tryParse(json['request_count']?.toString() ?? '0') ?? 0,
      totalInputTokens: int.tryParse(json['total_input_tokens']?.toString() ?? '0') ?? 0,
      totalOutputTokens: int.tryParse(json['total_output_tokens']?.toString() ?? '0') ?? 0,
      totalTokens: int.tryParse(json['total_tokens']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Usage totals
class UsageTotals {
  final int totalRequests;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalTokens;

  UsageTotals({
    required this.totalRequests,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalTokens,
  });

  factory UsageTotals.fromJson(Map<String, dynamic> json) {
    return UsageTotals(
      totalRequests: json['totalRequests'] as int? ?? 0,
      totalInputTokens: json['totalInputTokens'] as int? ?? 0,
      totalOutputTokens: json['totalOutputTokens'] as int? ?? 0,
      totalTokens: json['totalTokens'] as int? ?? 0,
    );
  }
}

/// Recent activity item
class RecentActivity {
  final String id;
  final String provider;
  final String model;
  final String service;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final DateTime createdAt;

  RecentActivity({
    required this.id,
    required this.provider,
    required this.model,
    required this.service,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.createdAt,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      model: json['model'] as String? ?? '',
      service: json['service'] as String? ?? '',
      inputTokens: json['inputTokens'] as int? ?? 0,
      outputTokens: json['outputTokens'] as int? ?? 0,
      totalTokens: json['totalTokens'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Daily usage breakdown
class DailyUsage {
  final String date;
  final String provider;
  final int requestCount;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  DailyUsage({
    required this.date,
    required this.provider,
    required this.requestCount,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
  });

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    return DailyUsage(
      date: json['date'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      requestCount: json['requestCount'] as int? ?? 0,
      inputTokens: json['inputTokens'] as int? ?? 0,
      outputTokens: json['outputTokens'] as int? ?? 0,
      totalTokens: json['totalTokens'] as int? ?? 0,
    );
  }
}
