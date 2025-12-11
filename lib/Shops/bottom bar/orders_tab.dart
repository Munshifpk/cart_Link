import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../constant.dart';
import '../../services/auth_state.dart';
import '../shop_order_detail_page.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _shopId;

  static const Map<String, String> _valueToDisplay = {
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'shipped': 'Shipped',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  // keep for reference (may be used later)
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
        
        String cust = '';
        String custPhone = '';
        String custEmail = '';
        
        if (m['customerId'] is Map) {
          cust = (m['customerId']['name'] ?? '').toString();
          custPhone = (m['customerId']['phone'] ?? '').toString();
          custEmail = (m['customerId']['email'] ?? '').toString();
        } else {
          cust = (m['customerId'] ?? '').toString();
        }
        
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
          customerName: cust,
          customerPhone: custPhone,
          customerEmail: custEmail,
          items: products.length,
          total: total,
          status: status,
          time: created,
          products: products,
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

  Future<void> _fetchOrdersByShopId(String shopId) async {
    try {
      final uri = backendUri('api/orders/shop/$shopId');
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load orders')),
          );
        setState(() => _loading = false);
        return;
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = j['data'] as List<dynamic>?;
      if (data == null) {
        setState(() => _loading = false);
        return;
      }

      print('Orders data: $data');

      final fetched = data.map((e) {
        final m = e as Map<String, dynamic>;
        final id = (m['_id'] ?? m['id'] ?? '').toString();

        String cust = '';
        String custPhone = '';
        String custEmail = '';

        final custObj = m['customerId'];
        if (custObj is Map) {
          cust = (custObj['customerName'] ?? custObj['name'] ?? '').toString().trim();
          custPhone = (custObj['mobile'] ?? custObj['phone'] ?? '').toString().trim();
          custEmail = (custObj['email'] ?? '').toString().trim();
        } else {
          cust = (m['customerId'] ?? '').toString();
        }

        if (cust.isEmpty) cust = 'Customer';

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
          customerName: cust,
          customerPhone: custPhone,
          customerEmail: custEmail,
          items: products.length,
          total: total,
          status: status,
          time: created,
          products: products,
        );
      }).toList();

      setState(() {
        _orders = fetched;
        _loading = false;
      });
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading orders')),
        );
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final shopId = AuthState.currentOwner?['_id'] ?? AuthState.currentOwner?['id'];
    print('Shop ID from auth: $shopId');
    print('Current owner: ${AuthState.currentOwner}');
    if (shopId != null) {
      _shopId = shopId.toString();
      _fetchOrdersByShopId(_shopId!);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshOrders() async {
    if (_shopId == null) return;
    setState(() => _loading = true);
    await _fetchOrdersByShopId(_shopId!);
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
    final readyForDelivery = _orders
        .where((o) => o.status.toLowerCase().contains('shipped'))
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

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : DefaultTabController(
            length: 4,
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
                      Tab(text: 'Pending'),
                      Tab(text: 'Ready for Delivery'),
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
                        onRefresh: _refreshOrders,
                        onOpenOrder: (order) async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopOrderDetailPage(order: order),
                            ),
                          );
                          if (changed == true) {
                            await _refreshOrders();
                          } else {
                            setState(() {});
                          }
                        },
                      ),
                      _OrdersList(
                        orders: readyForDelivery,
                        onUpdateStatus: (order, status) async {
                          final ok = await _updateOrderStatus(order.id, status);
                          if (ok) {
                            setState(() => order.status = status);
                          }
                          return ok;
                        },
                        onRefresh: _refreshOrders,
                        onOpenOrder: (order) async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopOrderDetailPage(order: order),
                            ),
                          );
                          if (changed == true) {
                            await _refreshOrders();
                          } else {
                            setState(() {});
                          }
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
                        onRefresh: _refreshOrders,
                        onOpenOrder: (order) async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopOrderDetailPage(order: order),
                            ),
                          );
                          if (changed == true) {
                            await _refreshOrders();
                          } else {
                            setState(() {});
                          }
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
                        onRefresh: _refreshOrders,
                        onOpenOrder: (order) async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopOrderDetailPage(order: order),
                            ),
                          );
                          if (changed == true) {
                            await _refreshOrders();
                          } else {
                            setState(() {});
                          }
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
   final Future<void> Function()? onRefresh;
   final Future<void> Function(Order order)? onOpenOrder;

  const _OrdersList({required this.orders, required this.onUpdateStatus, this.onRefresh, this.onOpenOrder});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) {
          await onRefresh!();
        } else {
          await Future.delayed(const Duration(milliseconds: 800));
        }
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
                    order.customerName,
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
                  Text('ID: ${order.id}'),
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
                if (onOpenOrder != null) {
                  await onOpenOrder!(order);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShopOrderDetailPage(order: order),
                    ),
                  );
                }
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
  final String? customerPhone;
  final String? customerEmail;
  final int items;
  final double total;
  String status;
  final DateTime time;
  final List<dynamic> products;

  Order({
    required this.id,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.items,
    required this.total,
    required this.status,
    required this.time,
    this.products = const [],
  });
}
