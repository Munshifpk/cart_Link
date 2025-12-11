import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constant.dart';
import '../theme_data.dart';

class OrdersAdmin extends StatefulWidget {
  const OrdersAdmin({super.key});

  @override
  State<OrdersAdmin> createState() => _OrdersAdminState();
}

class Order {
  final String id;
  final String customerName;
  final String details;
  final double total;
  String status;

  Order({
    required this.id,
    required this.customerName,
    required this.details,
    required this.total,
    required this.status,
  });
}

class _OrdersAdminState extends State<OrdersAdmin> {
  final List<Order> _orders = [
    Order(
      id: 'ORD-1001',
      customerName: 'Asha Patel',
      details: '2x Apples, 1x Milk',
      total: 12.50,
      status: 'Pending',
    ),
    Order(
      id: 'ORD-1002',
      customerName: 'Rahul Kumar',
      details: '1x Laptop Charger',
      total: 599.99,
      status: 'Processing',
    ),
    Order(
      id: 'ORD-1003',
      customerName: 'Meera Singh',
      details: '3x T-shirts',
      total: 45.00,
      status: 'Shipped',
    ),
    Order(
      id: 'ORD-1004',
      customerName: 'Karan Rao',
      details: '5x Bananas, 1x Bread',
      total: 8.75,
      status: 'Delivered',
    ),
    Order(
      id: 'ORD-1005',
      customerName: 'Lina George',
      details: '1x Phone Case',
      total: 9.99,
      status: 'Cancelled',
    ),
  ];

  // Statuses are displayed read-only in the table.

  // Map display labels to backend status values
  static const Map<String, String> _displayToValue = {
    'Pending': 'pending',
    'Confirmed': 'confirmed',
    'Shipped': 'shipped',
    'Completed': 'delivered',
    'Cancelled': 'cancelled',
  };

  static const List<String> _statusOptions = [
    'Pending',
    'Confirmed',
    'Shipped',
    'Completed',
    'Cancelled',
  ];

  // Map backend values to display labels
  static const Map<String, String> _valueToDisplay = {
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'shipped': 'Shipped',
    'delivered': 'Completed',
    'cancelled': 'Cancelled',
  };

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

      final List<Order> fetched = data.map((e) {
        final m = e as Map<String, dynamic>;
        final id = (m['_id'] ?? m['id'] ?? '').toString();
        final cust = (m['customerId'] is Map)
            ? (m['customerId']['name'] ?? m['customerId']['shopName'] ?? '')
            : (m['customerId'] ?? '');
        final products = (m['products'] as List<dynamic>?) ?? [];
        final details = products
            .map((p) {
              final pm = p as Map<String, dynamic>;
              final qty = pm['quantity']?.toString() ?? '1';
              final name = (pm['productId'] is Map)
                  ? (pm['productId']['name'] ?? pm['productId'].toString())
                  : (pm['productId']?.toString() ?? 'Item');
              return '$qty x $name';
            })
            .join(', ');
        final total = (m['totalAmount'] is num)
            ? (m['totalAmount'] as num).toDouble()
            : double.tryParse((m['totalAmount'] ?? '0').toString()) ?? 0.0;
        final statusRaw = (m['orderStatus'] ?? '').toString();
        final status =
            _valueToDisplay[statusRaw.toLowerCase()] ??
            (statusRaw.isNotEmpty ? statusRaw : 'Pending');
        return Order(
          id: id,
          customerName: cust.toString(),
          details: details,
          total: total,
          status: status,
        );
      }).toList();

      setState(() {
        _orders.clear();
        _orders.addAll(fetched);
      });
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

  Future<bool> _updateOrderStatusToBackend(
    Order order,
    String displayStatus,
  ) async {
    final backendStatus = _displayToValue[displayStatus];
    if (backendStatus == null) return false;

    try {
      final uri = backendUri('api/orders/${order.id}/status');
      final resp = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderStatus': backendStatus}),
      );

      if (resp.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void _showOrderDetails(Order order) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order ${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.customerName}'),
            const SizedBox(height: 8),
            Text('Items: ${order.details}'),
            const SizedBox(height: 8),
            Text('Total: ₹${order.total.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _statusOptions.contains(order.status)
                      ? order.status
                      : null,
                  hint: Text(order.status),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    final prev = order.status;
                    setState(() => order.status = v);
                    final ok = await _updateOrderStatusToBackend(order, v);
                    if (!ok) {
                      setState(() => order.status = prev);
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update status'),
                          ),
                        );
                    } else {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Status updated')),
                        );
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: ThemeColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Load by customer ID',
            onPressed: () async {
              final controller = TextEditingController();
              final res = await showDialog<String?>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Load orders'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Customer ID'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(controller.text),
                      child: const Text('Load'),
                    ),
                  ],
                ),
              );
              if (res != null && res.trim().isNotEmpty) {
                await _fetchOrdersByCustomerId(res.trim());
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => ThemeColors.primary,
                ),
                headingRowHeight: 56,
                dataRowMinHeight: 70,
                dataRowMaxHeight: 70,
                columnSpacing: 20,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Order ID',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Customer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                rows: List.generate(_orders.length, (index) {
                  final o = _orders[index];
                  return DataRow(
                    cells: [
                      DataCell(Text(o.id)),
                      DataCell(Text(o.customerName)),
                      DataCell(Text(o.details)),
                      DataCell(Text('₹${o.total.toStringAsFixed(2)}')),
                      DataCell(
                        DropdownButton<String>(
                          value: _statusOptions.contains(o.status)
                              ? o.status
                              : null,
                          hint: Text(
                            o.status.isNotEmpty ? o.status : 'Pending',
                          ),
                          items: _statusOptions
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) async {
                            if (v == null) return;
                            final prev = o.status;
                            setState(() => o.status = v);
                            final ok = await _updateOrderStatusToBackend(o, v);
                            if (!ok) {
                              setState(() => o.status = prev);
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to update status'),
                                  ),
                                );
                            } else {
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Status updated'),
                                  ),
                                );
                            }
                          },
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'Details',
                          onPressed: () => _showOrderDetails(o),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
