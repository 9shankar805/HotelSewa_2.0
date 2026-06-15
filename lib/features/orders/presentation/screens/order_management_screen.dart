import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/owner/ordering_service.dart';
import '../../../../core/constants/app_colors.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String? _selectedStatus;
  int _currentPage = 1;
  int _totalPages = 1;

  final List<Map<String, dynamic>> _statusFilters = [
    {'value': null, 'label': 'All', 'color': AppColors.gray},
    {'value': 'pending', 'label': '⏳ Pending', 'color': AppColors.warning},
    {'value': 'confirmed', 'label': '✅ Confirmed', 'color': AppColors.info},
    {'value': 'preparing', 'label': '👨‍🍳 Preparing', 'color': Colors.purple},
    {'value': 'ready', 'label': '🔔 Ready', 'color': AppColors.success},
    {'value': 'delivered', 'label': '✅ Delivered', 'color': Colors.teal},
    {'value': 'cancelled', 'label': '❌ Cancelled', 'color': AppColors.error},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? prefs.getString('auth_token');

      if (token == null) {
        _showError('Please login first');
        return;
      }

      final response = await OrderingService.getHotelOrders(
        token: token,
        status: _selectedStatus,
        page: _currentPage,
        perPage: 20,
      );

      if (response['status'] == true) {
        final data = response['data'];
        setState(() {
          _orders = data['data'] ?? [];
          _currentPage = data['current_page'] ?? 1;
          _totalPages = (data['total'] / (data['per_page'] ?? 20)).ceil();
          _isLoading = false;
        });
      } else {
        _showError(response['message'] ?? 'Failed to load orders');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _statusFilters.map((filter) {
          final isSelected = _selectedStatus == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? filter['value'] as String? : null;
                  _currentPage = 1;
                });
                _loadOrders();
              },
              backgroundColor: AppColors.gray[200],
              selectedColor: (filter['color'] as Color).withOpacity(0.2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: AppColors.gray[400]),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: TextStyle(fontSize: 18, color: AppColors.gray[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final statusInfo = _statusFilters.firstWhere(
      (f) => f['value'] == status,
      orElse: () => _statusFilters[0],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: (statusInfo['color'] as Color).withOpacity(0.2),
          child: Text(
            order['room_number'] ?? '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusInfo['color'] as Color,
            ),
          ),
        ),
        title: Text(
          order['order_number'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusInfo['label'] as String),
            Text(
              '${order['currency']} ${order['total_amount']}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          ],
        ),
        children: [
          _buildOrderDetails(order),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final user = order['user'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null) ...[
            Text('Guest: ${user['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Phone: ${user['phone'] ?? 'N/A'}'),
            const Divider(height: 24),
          ],
          const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item['quantity']}x ${item['item_name']}'),
                    ),
                    Text('${order['currency']} ${item['total_price']}'),
                  ],
                ),
              )),
          if (order['special_instructions'] != null) ...[
            const Divider(height: 24),
            const Text('Special Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(order['special_instructions']),
          ],
          const Divider(height: 24),
          _buildStatusActions(order),
        ],
      ),
    );
  }

  Widget _buildStatusActions(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final orderId = order['id'] as int;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (status == 'pending')
          ElevatedButton.icon(
            onPressed: () => _updateStatus(orderId, 'confirmed'),
            icon: const Icon(Icons.check),
            label: const Text('Confirm'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
          ),
        if (status == 'confirmed')
          ElevatedButton.icon(
            onPressed: () => _updateStatus(orderId, 'preparing'),
            icon: const Icon(Icons.restaurant),
            label: const Text('Start Preparing'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        if (status == 'preparing')
          ElevatedButton.icon(
            onPressed: () => _updateStatus(orderId, 'ready'),
            icon: const Icon(Icons.notifications),
            label: const Text('Mark Ready'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          ),
        if (status == 'ready')
          ElevatedButton.icon(
            onPressed: () => _updateStatus(orderId, 'delivered'),
            icon: const Icon(Icons.done_all),
            label: const Text('Mark Delivered'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
        if (status == 'pending' || status == 'confirmed')
          OutlinedButton.icon(
            onPressed: () => _updateStatus(orderId, 'cancelled'),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          ),
      ],
    );
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? prefs.getString('auth_token');

      final response = await OrderingService.updateOrderStatus(
        token: token!,
        orderId: orderId,
        status: newStatus,
      );

      if (response['status'] == true) {
        _showSuccess('Order status updated');
        _loadOrders();
      } else {
        _showError(response['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }
}
