import 'package:url_launcher/url_launcher.dart';
import '../models/billing_models.dart';
import '../config/env_config.dart';
import '../core/utils/logger.dart';
import 'api_client.dart';

/// Service for billing and credits management
class BillingService {
  final ApiClient _apiClient;

  BillingService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get current credits balance
  Future<double> getCreditsBalance() async {
    try {
      final response = await _apiClient.get('/billing/credits');
      return (response['creditsBalance'] as num?)?.toDouble() ?? 0.0;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting credits balance', e, stackTrace);
      return 0.0;
    }
  }

  /// Get billing status (enabled, balance, pricing)
  Future<BillingStatus> getBillingStatus() async {
    try {
      final response = await _apiClient.get('/billing/status');
      return BillingStatus.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting billing status', e, stackTrace);
      return BillingStatus(enabled: false, creditsBalance: 0.0, pricing: {});
    }
  }

  /// Get pricing information (public endpoint)
  Future<Map<String, ModelPricing>> getPricing() async {
    try {
      final response = await _apiClient.get('/billing/pricing');
      final pricingJson = response['pricing'] as Map<String, dynamic>?;
      if (pricingJson == null) return {};

      return pricingJson.map(
        (key, value) => MapEntry(key, ModelPricing.fromJson(value as Map<String, dynamic>)),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error getting pricing', e, stackTrace);
      return {};
    }
  }

  /// Get billing summary (balance, transactions, payments, usage stats)
  Future<BillingSummary> getBillingSummary() async {
    try {
      final response = await _apiClient.get('/billing/summary');
      return BillingSummary.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting billing summary', e, stackTrace);
      return BillingSummary(
        creditsBalance: 0.0,
        transactions: [],
        payments: [],
        usageStats: [],
      );
    }
  }

  /// Get transaction history
  Future<List<Transaction>> getTransactions({int limit = 50, int offset = 0}) async {
    try {
      final response = await _apiClient.get('/billing/transactions?limit=$limit&offset=$offset');
      final transactionsJson = response['transactions'] as List<dynamic>?;
      if (transactionsJson == null) return [];

      return transactionsJson
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting transactions', e, stackTrace);
      return [];
    }
  }

  /// Purchase credits - returns checkout URL
  Future<CheckoutSession> purchaseCredits(double amount) async {
    if (amount < 5) {
      throw Exception('Minimum purchase amount is \$5');
    }

    final appBaseUrl = EnvConfig.appBaseUrl;

    final response = await _apiClient.post('/billing/purchase', {
      'amount': amount,
      'successUrl': '$appBaseUrl/billing/success',
      'cancelUrl': '$appBaseUrl/billing',
    });

    return CheckoutSession.fromJson(response);
  }

  /// Open Stripe checkout in browser
  Future<bool> openCheckout(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Get usage summary
  Future<UsageSummary> getUsageSummary({int? days}) async {
    try {
      String url = '/ai/usage';
      if (days != null) {
        url += '?days=$days';
      }
      final response = await _apiClient.get(url);
      return UsageSummary.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting usage summary', e, stackTrace);
      return UsageSummary(
        summary: [],
        totals: UsageTotals(
          totalRequests: 0,
          totalInputTokens: 0,
          totalOutputTokens: 0,
          totalTokens: 0,
        ),
        recentActivity: [],
      );
    }
  }

  /// Get daily usage breakdown
  Future<List<DailyUsage>> getDailyUsage({int days = 30}) async {
    try {
      final response = await _apiClient.get('/ai/usage/daily?days=$days');
      final dailyJson = response['daily'] as List<dynamic>?;
      if (dailyJson == null) return [];

      return dailyJson
          .map((e) => DailyUsage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting daily usage', e, stackTrace);
      return [];
    }
  }

  /// Check if user has sufficient credits
  Future<bool> hasSufficientCredits({double minimumRequired = 0.01}) async {
    final balance = await getCreditsBalance();
    return balance >= minimumRequired;
  }

  /// Check if credits are low (below threshold)
  Future<bool> isLowBalance({double threshold = 1.0}) async {
    final balance = await getCreditsBalance();
    return balance < threshold;
  }
}
