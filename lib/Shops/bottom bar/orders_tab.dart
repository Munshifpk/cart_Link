import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../constant.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<Order> _orders = [];

  static const Map<String, String> _valueToDisplay = {
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'shipped': 'Shipped',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  // keep for reference (may be used later)
  // ignore: unused_field
  static const List<String> _statusOptions = [
    'Pending',
    'Confirmed',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  // ignore: unused_element
  Future<void> _fetchOrdersByCustomerId(String customerId) async {
    try {
      final uri = backendUri('api/orders/customer/$customerId');
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load orders')),
          );
        return;
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = j['data'] as List<dynamic>?;
      if (data == null) return;

      final fetched = data.map((e) {
        final m = e as Map<String, dynamic>;
        final id = (m['_id'] ?? m['id'] ?? '').toString();
        final cust = (m['customerId'] is Map)
            ? (m['customerId']['name'] ?? '')
            : (m['customerId'] ?? '');
        final products = (m['products'] as List<dynamic>?) ?? [];
        final total = (m['totalAmount'] is num)
            ? (m['totalAmount'] as num).toDouble()
            : double.tryParse((m['totalAmount'] ?? '0').toString()) ?? 0.0;
        final statusRaw = (m['orderStatus'] ?? '').toString();
        final status =
            _valueToDisplay[statusRaw.toLowerCase()] ??
            (statusRaw.isNotEmpty ? statusRaw : 'Pending');
        final created =
            DateTime.tryParse((m['createdAt'] ?? '').toString()) ??
            DateTime.now();
        return Order(
          id: id,
          customerName: cust.toString(),
          items: products.length,
          total: total,
          status: status,
          time: created,
        );
      }).toList();

      setState(() => _orders = fetched);
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Orders loaded')));
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error loading orders')));
    }
  }

  Future<bool> _updateOrderStatus(String orderId, String displayStatus) async {
    final map = {
      'Pending': 'pending',
      'Confirmed': 'confirmed',
      'Shipped': 'shipped',
      'Delivered': 'delivered',
      'Cancelled': 'cancelled',
    };
    final backend = map[displayStatus];
    if (backend == null) return false;
    try {
      final uri = backendUri('api/orders/$orderId/status');
      final resp = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderStatus': backend}),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _orders
        .where(
          (o) =>
              o.status.toLowerCase().contains('pending') ||
              o.status.toLowerCase().contains('confirm'),
        )
        .toList();
    final completed = _orders
        .where(
          (o) =>
              o.status.toLowerCase().contains('deliver') ||
              o.status.toLowerCase().contains('delivered'),
        )
        .toList();
    final cancelled = _orders
        .where((o) => o.status.toLowerCase().contains('cancel'))
        .toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF0D47A1),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Pending Orders'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OrdersList(
                  orders: pending,
                  onUpdateStatus: (order, status) async {
                    final ok = await _updateOrderStatus(order.id, status);
                    if (ok) {
                      setState(() => order.status = status);
                    }
                    return ok;
                  },
                ),
                _OrdersList(
                  orders: completed,
                  onUpdateStatus: (order, status) async {
                    final ok = await _updateOrderStatus(order.id, status);
                    if (ok) {
                      setState(() => order.status = status);
                    }
                    return ok;
                  },
                ),
                _OrdersList(
                  orders: cancelled,
                  onUpdateStatus: (order, status) async {
                    final ok = await _updateOrderStatus(order.id, status);
                    if (ok) {
                      setState(() => order.status = status);
                    }
                    return ok;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<Order> orders;
  final Future<bool> Function(Order order, String status) onUpdateStatus;

  const _OrdersList({required this.orders, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement refresh logic
        await Future.delayed(const Duration(milliseconds: 800));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: order.status == 'Pending'
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
                child: Icon(
                  order.status == 'Pending'
                      ? Icons.pending_outlined
                      : Icons.check_circle_outline,
                  color: order.status == 'Pending'
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: order.status == 'Pending'
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: order.status == 'Pending'
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(order.customerName),
                  const SizedBox(height: 4),
                  Text(
                    '${order.items} items • ₹${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(order.time),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              onTap: () async {
                // show order details with status change option
                final options = [
                  'Pending',
                  'Confirmed',
                  'Shipped',
                  'Delivered',
                  'Cancelled',
                ];
                await showDialog<void>(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: Text('Order ${order.id}'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer: ${order.customerName}'),
                          const SizedBox(height: 8),
                          Text(
                            '${order.items} items • ₹${order.total.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Status: '),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: options.contains(order.status)
                                    ? order.status
                                    : null,
                                hint: Text(order.status),
                                items: options
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) async {
                                  if (v == null) return;
                                  // optimistic update in UI via callback return
                                  final ok = await onUpdateStatus(order, v);
                                  if (!ok) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to update status',
                                          ),
                                        ),
                                      );
                                  } else {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Status updated'),
                                        ),
                                      );
                                  }
                                  Navigator.of(ctx).pop();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class Order {
  final String id;
  final String customerName;
  final int items;
  final double total;
  String status;
  final DateTime time;

  Order({
    required this.id,
    required this.customerName,
    required this.items,
    required this.total,
    required this.status,
    required this.time,
  });
}
