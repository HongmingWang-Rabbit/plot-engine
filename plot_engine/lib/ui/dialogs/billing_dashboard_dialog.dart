import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_state.dart';
import '../../models/billing_models.dart';
import '../../services/billing_service.dart';

class BillingDashboardDialog extends ConsumerStatefulWidget {
  const BillingDashboardDialog({super.key});

  @override
  ConsumerState<BillingDashboardDialog> createState() => _BillingDashboardDialogState();
}

class _BillingDashboardDialogState extends ConsumerState<BillingDashboardDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _purchaseAmount = 10.0;
  bool _isPurchasing = false;
  bool _isLoading = true;

  BillingSummary? _summary;
  UsageSummary? _usageSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final billingService = ref.read(billingServiceProvider);

    try {
      final summary = await billingService.getBillingSummary();
      final usage = await billingService.getUsageSummary(days: 30);

      if (mounted) {
        setState(() {
          _summary = summary;
          _usageSummary = usage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final creditsBalance = ref.watch(creditsBalanceNotifierProvider) ?? 0.0;

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Credits & Billing',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Balance: \$${creditsBalance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Purchase', icon: Icon(Icons.add_card, size: 18)),
                Tab(text: 'Usage', icon: Icon(Icons.analytics, size: 18)),
                Tab(text: 'History', icon: Icon(Icons.history, size: 18)),
              ],
            ),
            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPurchaseTab(creditsBalance),
                        _buildUsageTab(),
                        _buildHistoryTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseTab(double creditsBalance) {
    final billingService = ref.read(billingServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: creditsBalance > 1
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : [Colors.orange.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (creditsBalance > 1 ? Colors.green : Colors.orange).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.account_balance_wallet, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Current Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${creditsBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (creditsBalance < 1)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Low balance',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Purchase Section
          Text(
            'Add Credits',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Amount Selection
          Row(
            children: [
              _buildAmountChip(5),
              const SizedBox(width: 8),
              _buildAmountChip(10),
              const SizedBox(width: 8),
              _buildAmountChip(25),
              const SizedBox(width: 8),
              _buildAmountChip(50),
            ],
          ),
          const SizedBox(height: 16),

          // Purchase Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isPurchasing ? null : () => _handlePurchase(billingService),
              icon: _isPurchasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.shopping_cart),
              label: Text(
                _isPurchasing
                    ? 'Processing...'
                    : 'Purchase \$${_purchaseAmount.toStringAsFixed(0)} Credits',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Credits are used for AI features. Minimum purchase is \$5. Payments are processed securely via Stripe.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChip(double amount) {
    final isSelected = _purchaseAmount == amount;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _purchaseAmount = amount),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '\$${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageTab() {
    if (_usageSummary == null) {
      return const Center(child: Text('No usage data available'));
    }

    final totals = _usageSummary!.totals;
    final summary = _usageSummary!.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Totals Row
          Row(
            children: [
              Expanded(child: _buildStatCard('Requests', '${totals.totalRequests}', Icons.send)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Input Tokens', _formatNumber(totals.totalInputTokens), Icons.input)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Output Tokens', _formatNumber(totals.totalOutputTokens), Icons.output)),
            ],
          ),
          const SizedBox(height: 24),

          // Usage by Service
          Text(
            'Usage by Service (Last 30 Days)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (summary.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('No usage recorded yet'),
              ),
            )
          else
            ...summary.map((s) => _buildUsageRow(s)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageRow(ServiceUsage usage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Icon(Icons.auto_awesome, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usage.service,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${usage.provider} • ${usage.requestCount} requests',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatNumber(usage.totalTokens)} tokens',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final transactions = _summary?.transactions ?? [];

    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No transactions yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _buildTransactionRow(tx);
      },
    );
  }

  Widget _buildTransactionRow(Transaction tx) {
    final isCredit = tx.amount > 0;
    final icon = tx.isPurchase
        ? Icons.add_card
        : tx.isUsage
            ? Icons.auto_awesome
            : tx.isRefund
                ? Icons.replay
                : Icons.card_giftcard;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDateTime(tx.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : ''}\$${tx.amount.toStringAsFixed(4)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              Text(
                'Bal: \$${tx.balanceAfter.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toString();
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return 'Today ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${dt.month}/${dt.day}/${dt.year}';
    }
  }

  Future<void> _handlePurchase(BillingService billingService) async {
    setState(() => _isPurchasing = true);

    try {
      final session = await billingService.purchaseCredits(_purchaseAmount);
      if (session.url.isNotEmpty) {
        await billingService.openCheckout(session.url);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Redirecting to payment page...')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }
}
