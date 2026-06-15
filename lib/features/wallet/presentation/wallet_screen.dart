import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _walletService = WalletService();
  bool _loading = true;
  String? _error;
  double _walletBalance = 0;
  double _pointsBalance = 0;
  double _totalSpent = 0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // GET /wallet — returns balance, points, transactions together
      final walletResult = await _walletService.getWallet();
      if (walletResult['success'] == true) {
        final data = walletResult['wallet'] ?? {};
        _walletBalance = (data['balance'] ?? data['wallet_balance'] ?? 0 as num).toDouble();
        _pointsBalance = (data['points_balance'] ?? data['loyalty_points'] ?? 0 as num).toDouble();
        _totalSpent = (data['total_spent'] ?? 0 as num).toDouble();

        // Transactions may be embedded or separate
        List txnList = [];
        if (data['transactions'] is List) {
          txnList = data['transactions'] as List;
        } else {
          // Fall back to payment transactions endpoint
          final txnResult = await _walletService.getWalletTransactions(limit: 20);
          if (txnResult['success'] == true) {
            final txnData = txnResult['transactions'];
            txnList = txnData is List ? txnData : (txnData is Map ? (txnData['data'] ?? txnData['transactions'] ?? []) : []);
          }
        }

        // Calculate total spent from transactions if not provided
        if (_totalSpent == 0 && txnList.isNotEmpty) {
          _totalSpent = txnList
              .where((t) => t['type'] == 'debit')
              .fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
        }

        setState(() {
          _transactions = List<Map<String, dynamic>>.from(txnList);
          _loading = false;
        });
      } else {
        setState(() { _error = walletResult['message'] ?? 'Failed to load wallet'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load wallet'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Balance card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppColors.primaryShadow,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Available Balance', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                    child: const Text('Primary', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text('NPR ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ),
                                  Text(_walletBalance.toStringAsFixed(0), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    _infoItem(Icons.diamond_rounded, '${_pointsBalance.toInt()}', 'Points'),
                                    Container(width: 1, height: 24, color: Colors.white24),
                                    _infoItem(Icons.shopping_bag_rounded, 'NPR ${_totalSpent.toInt()}', 'Spent'),
                                    Container(width: 1, height: 24, color: Colors.white24),
                                    _infoItem(Icons.auto_graph_rounded, '+12%', 'Growth'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Action buttons
                        Row(
                          children: [
                            _actionBtn(Icons.add_circle_outline_rounded, 'Add Money', () => context.push('/payment-methods')),
                            const SizedBox(width: 16),
                            _actionBtn(Icons.send_rounded, 'Transfer', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer feature coming soon')))),
                            const SizedBox(width: 16),
                            _actionBtn(Icons.history_rounded, 'Stats', () => _load()),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Transactions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
                            TextButton(onPressed: () => context.push('/transaction-history'), child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_transactions.isEmpty)
                          _buildEmpty()
                        else
                          ..._transactions.map((txn) => _buildTxnItem(txn)),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _infoItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildTxnItem(Map<String, dynamic> txn) {
    final isCredit = txn['type'] == 'credit';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isCredit ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isCredit ? Icons.add_rounded : Icons.remove_rounded, color: isCredit ? AppColors.success : AppColors.error),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn['desc'] ?? txn['description'] ?? 'Transaction', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                const SizedBox(height: 4),
                Text(txn['date'] ?? txn['created_at'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'} NPR ${txn['amount']}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isCredit ? AppColors.success : AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.placeholder),
      const SizedBox(height: 16),
      Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.gray), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Retry', style: TextStyle(color: Colors.white))),
    ])));
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: AppColors.placeholder.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No transactions yet', style: TextStyle(color: AppColors.gray, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
