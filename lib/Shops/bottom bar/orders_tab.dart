import 'package:flutter/material.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF0D47A1),
            child: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'Pending Orders'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Pending Orders Tab
                _OrdersList(
                  orders: List.generate(
                    5,
                    (i) => Order(
                      id: 'ORD${1000 + i}',
                      customerName: 'Customer ${i + 1}',
                      items: 3 + i,
                      total: 1250.0 + (i * 100),
                      status: 'Pending',
                      time: DateTime.now().subtract(Duration(hours: i)),
                    ),
                  ),
                ),

                // Completed Orders Tab
                _OrdersList(
                  orders: List.generate(
                    8,
                    (i) => Order(
                      id: 'ORD${2000 + i}',
                      customerName: 'Customer ${10 + i}',
                      items: 2 + i,
                      total: 950.0 + (i * 150),
                      status: 'Delivered',
                      time: DateTime.now().subtract(Duration(days: i)),
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
}

class _OrdersList extends StatelessWidget {
  final List<Order> orders;

  const _OrdersList({required this.orders});

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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
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
              onTap: () {
                // TODO: Navigate to order details
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('View Order ${order.id}')),
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
  final String status;
  final DateTime time;

  const Order({
    required this.id,
    required this.customerName,
    required this.items,
    required this.total,
    required this.status,
    required this.time,
  });
}
