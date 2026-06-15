import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/api_config.dart';
import '../../../earnings/presentation/services/earnings_service.dart';

class WithdrawalsScreen extends StatefulWidget {
  const WithdrawalsScreen({super.key});
  @override
  State<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends State<WithdrawalsScreen> {
  bool _loading = true;
  bool _requesting = false;
  List<Map<String, dynamic>> _withdrawals = [];
  double _availableBalance = 0;
  String? _token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('authToken');
      EarningsService.setToken(_token!);
      final list = await EarningsService.fetchWithdrawals();
      final earnings = await EarningsService.getEarnings();
      setState(() {
        _withdrawals = list;
        _availableBalance = (earnings['available_balance'] ?? earnings['pending_amount'] ?? earnings['balance'] ?? 0).toDouble();
      });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _requestWithdrawal() async {
    final amtCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Withdrawal', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_rounded, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text('Available: NPR ${_availableBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (NPR)', border: OutlineInputBorder(), prefixText: 'NPR ')),
          const SizedBox(height: 12),
          TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: accountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
            child: const Text('Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (result != true) return;
    final amount = double.tryParse(amtCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    if (amount > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount exceeds available balance'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _requesting = true);
    try {
      final resp = await EarningsService.createWithdrawal({
        'amount': amount,
        'bank_name': bankCtrl.text.trim(),
        'account_number': accountCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed': case 'paid': return AppColors.success;
      case 'pending': case 'processing': return AppColors.warning;
      case 'failed': case 'rejected': return AppColors.error;
      default: return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: AppColors.darkGray,
        title: const Text('Withdrawals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load, color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // Balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('NPR ${_availableBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _requesting || _availableBalance <= 0 ? null : _requestWithdrawal,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF10B981), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _requesting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Request Withdrawal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  // History
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Withdrawal History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                    Text('${_withdrawals.length} records', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                  ]),
                  const SizedBox(height: 12),
                  if (_withdrawals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: const Column(children: [
                        Icon(Icons.south_rounded, size: 48, color: AppColors.placeholder),
                        SizedBox(height: 12),
                        Text('No withdrawals yet', style: TextStyle(fontSize: 15, color: AppColors.gray, fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('Your withdrawal history will appear here', style: TextStyle(fontSize: 12, color: AppColors.placeholder)),
                      ]),
                    )
                  else
                    ..._withdrawals.map((w) {
                      final amount = (w['amount'] ?? 0).toDouble();
                      final status = w['status']?.toString() ?? 'pending';
                      final date = w['created_at']?.toString().split('T')[0] ?? w['date']?.toString() ?? '';
                      final bank = w['bank_name']?.toString() ?? w['bank'] ?? '';
                      final color = _statusColor(status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Row(children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.south_rounded, color: color, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('NPR ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
                            if (bank.isNotEmpty) Text(bank, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                            if (date.isNotEmpty) Text(date, style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                          ),
                        ]),
                      );
                    }),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
    );
  }
}
