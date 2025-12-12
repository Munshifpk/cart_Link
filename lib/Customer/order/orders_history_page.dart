import 'package:flutter/material.dart';
import 'dart:convert';

import '../../theme_data.dart';
import '../../services/order_service.dart';
import '../../services/auth_state.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';
import 'order_detail_page.dart';

class OrdersHistoryPage extends StatefulWidget {
  const OrdersHistoryPage({super.key});

  @override
  State<OrdersHistoryPage> createState() => _OrdersHistoryPageState();
}

class _OrdersHistoryPageState extends State<OrdersHistoryPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final customer = AuthState.currentCustomer;
    if (customer == null) {
      setState(() {
        _error = 'Not logged in.';
        _loading = false;
      });
      return;
    }
    final customerId = customer['_id'] ?? customer['id'];
    final result = await OrderService.getCustomerOrders(customerId: customerId);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _orders = result['data'] ?? [];
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['message'] ?? 'Failed to fetch orders.';
        _loading = false;
      });
    }
  }

  Future<bool> _updateOrderStatus(String orderId, String status) async {
    try {
      final uri = backendUri('/api/orders/$orderId/status');
      final res = await http
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'orderStatus': status}),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _submitCancellationFeedback(
    String orderId,
    String feedback,
  ) async {
    try {
      final uri = backendUri('/api/orders/$orderId/feedback');
      final customerId =
          AuthState.currentCustomer?['_id'] ?? AuthState.currentCustomer?['id'];
      final customerName = AuthState.currentCustomer?['name'] ?? 'Anonymous';
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'orderId': orderId,
              'customerId': customerId,
              'customerName': customerName,
              'feedback': feedback,
              'type': 'cancellation',
              'createdAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: ThemeColors.primary,
        foregroundColor: ThemeColors.textColorWhite,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ThemeColors.textColorWhite,
          unselectedLabelColor: Colors.white70,
          labelColor: ThemeColors.textColorWhite,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(
                  _orders.where((o) => _isPending(o['orderStatus'])).toList(),
                  emptyLabel: 'No pending orders.',
                ),
                _buildOrderList(
                  _orders.where((o) => _isCompleted(o['orderStatus'])).toList(),
                  emptyLabel: 'No completed orders.',
                ),
                _buildOrderList(
                  _orders.where((o) => _isCancelled(o['orderStatus'])).toList(),
                  emptyLabel: 'No cancelled orders.',
                ),
              ],
            ),
    );
  }

  bool _isPending(String? status) {
    return status == null ||
        status == 'pending' ||
        status == 'confirmed' ||
        status == 'processing' ||
        status == 'shipped';
  }

  bool _isCompleted(String? status) {
    return status == 'delivered';
  }

  bool _isCancelled(String? status) {
    return status == 'cancelled';
  }

  Widget _buildOrderList(List<dynamic> orders, {required String emptyLabel}) {
    if (orders.isEmpty) {
      return Center(child: Text(emptyLabel));
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          final status = order['orderStatus'] ?? 'pending';
          final statusColor = status == 'delivered'
              ? Colors.green
              : status == 'cancelled'
              ? Colors.red
              : status == 'shipped'
              ? Colors.blue
              : Colors.orange;
          final shop = order['shopId'] is Map
              ? order['shopId']['name'] ?? ''
              : '';
          final date = order['createdAt'] != null
              ? order['createdAt'].toString().substring(0, 10)
              : '';
          final total = order['totalAmount'] ?? 0.0;
          final products = (order['products'] as List?) ?? [];
          final itemCount = products.fold<int>(
            0,
            (sum, p) => sum + ((p['quantity'] ?? 0) as int),
          );

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  builder: (context) => _buildOrderDetailsSheet(order),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 18,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.15),
                      child: Icon(
                        status == 'delivered'
                            ? Icons.check_circle
                            : status == 'cancelled'
                            ? Icons.cancel
                            : status == 'shipped'
                            ? Icons.local_shipping
                            : Icons.schedule,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${_shortId(order['_id'])}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$shop • $date',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Items: $itemCount',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _shortId(dynamic id) {
    try {
      final s = id?.toString() ?? '';
      if (s.isEmpty) return '';
      return s.length > 6
          ? s.substring(s.length - 6).toUpperCase()
          : s.toUpperCase();
    } catch (_) {
      return '';
    }
  }

  Widget _buildOrderDetailsSheet(dynamic order) {
    // Capture parent context for navigation after closing the sheet
    final parentContext = context;
    final shop = order['shopId'] is Map ? order['shopId']['name'] ?? '' : '';
    final date = order['createdAt'] != null
        ? order['createdAt'].toString().substring(0, 19).replaceAll('T', ' ')
        : '';
    final total = order['totalAmount'] ?? 0.0;
    final status = order['orderStatus'] ?? 'pending';
    final products = (order['products'] as List?) ?? [];
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text(
                shop,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Order ID: ${order['_id']}',
            style: const TextStyle(color: Colors.black54),
          ),
          Text('Date: $date', style: const TextStyle(color: Colors.black54)),
          const Divider(height: 24),
          const Text(
            'Items:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          ...products.map<Widget>((p) {
            final prod = p['productId'];
            final name = prod is Map ? prod['name'] ?? 'Product' : 'Product';
            final qty = p['quantity'] ?? 0;
            final price = p['price'] ?? 0.0;
            final mrp = p['mrp'] ?? price;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text('x$qty', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(width: 8),
                  Text(
                    '₹${price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if ((mrp - price) > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'MRP: ₹${mrp.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black54,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Future.microtask(() {
                  Navigator.of(parentContext).push(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailPage(
                        order: Map<String, dynamic>.from(order as Map),
                      ),
                    ),
                  );
                });
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('View Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (status != 'cancelled' && status != 'delivered')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Cancel Order'),
                      content: const Text(
                        'Are you sure you want to cancel this order?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('No'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;

                  // Show feedback dialog
                  if (!mounted) return;
                  final feedbackCtrl = TextEditingController();
                  final feedbackResult = await showDialog<String>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Cancellation Feedback'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Please let us know why you are cancelling this order:',
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: feedbackCtrl,
                              decoration: InputDecoration(
                                hintText: 'Your feedback...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Skip'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(c, feedbackCtrl.text),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  );

                  // attempt cancel
                  final id = order['_id'] ?? order['id'];
                  if (id == null) return;
                  final ok = await _updateOrderStatus(
                    id.toString(),
                    'cancelled',
                  );
                  if (ok) {
                    // Submit feedback if provided
                    if (feedbackResult != null && feedbackResult.isNotEmpty) {
                      await _submitCancellationFeedback(
                        id.toString(),
                        feedbackResult,
                      );
                    }
                    if (mounted) {
                      setState(() {
                        try {
                          if (order is Map) order['orderStatus'] = 'cancelled';
                        } catch (_) {}
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(content: Text('Order cancelled')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(content: Text('Failed to cancel order')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Order'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
