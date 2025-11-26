import 'package:cart_link/Shops/analytics/cancelled_orders_page.dart';
import 'package:cart_link/Shops/analytics/compleated_orders_page.dart';
import 'package:cart_link/Shops/analytics/pending_orders_page.dart';
import 'package:cart_link/Shops/analytics/ready_to_delivery_page.dart';
import 'package:cart_link/Shops/analytics/orders_analytics.dart';
import 'package:flutter/material.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Analytics data
  final Map<String, int> _analyticsData = {
    'totalOrders': 156,
    'completedOrders': 142,
    'cancelledOrders': 8,
    'pendingOrders': 6,
    'readyToDeliver': 4,
    'totalSales': 45280,
    'confirmedOrders': 148,
    'refundedOrders': 5,
    'returnedOrders': 3,
  };

  final List<Map<String, dynamic>> _orderTrend = [
    {'date': 'Nov 18', 'orders': 12, 'sales': 3500},
    {'date': 'Nov 19', 'orders': 15, 'sales': 4200},
    {'date': 'Nov 20', 'orders': 18, 'sales': 5100},
    {'date': 'Nov 21', 'orders': 22, 'sales': 6300},
    {'date': 'Nov 22', 'orders': 28, 'sales': 7850},
    {'date': 'Nov 23', 'orders': 31, 'sales': 8900},
    {'date': 'Nov 24', 'orders': 30, 'sales': 9430},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdersAnalyticsPage(),
                      ),
                    );
                  },
                  child: _buildStatCard(
                    title: 'Total Orders',
                    value: _analyticsData['totalOrders'].toString(),
                    icon: Icons.shopping_bag,
                    color: Colors.blue,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConfirmedOrdersPage(),
                      ),
                    );
                  },
                  child: _buildStatCard(
                    title: 'Completed',
                    value: (_analyticsData['completedOrders'] ?? 0).toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CancelledOrdersPage(),
                      ),
                    );
                  },
                  child: _buildStatCard(
                    title: 'Cancelled',
                    value: (_analyticsData['cancelledOrders'] ?? 0).toString(),
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PendingOrdersPage(),
                      ),
                    );
                  },
                  child: _buildStatCard(
                    title: 'Pending',
                    value: (_analyticsData['pendingOrders'] ?? 0).toString(),
                    icon: Icons.schedule,
                    color: Colors.orange,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReadyToDeliveryPage(),
                      ),
                    );
                  },
                  child: _buildStatCard(
                    title: 'Ready to Deliver',
                    value: (_analyticsData['readyToDeliver'] ?? 0).toString(),
                    icon: Icons.local_shipping,
                    color: Colors.teal,
                  ),
                ),
                _buildStatCard(
                  title: 'Total Sales',
                  value: '₹${_analyticsData['totalSales']}',
                  icon: Icons.trending_up,
                  color: Colors.indigo,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Order Trend Section
            const Text(
              'Order Trend (Last 7 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Orders & Sales',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_orderTrend.length, (index) {
                          final trend = _orderTrend[index];
                          final maxOrders = _orderTrend
                              .map((t) => t['orders'] as int)
                              .reduce((a, b) => a > b ? a : b);
                          final barHeight =
                              (trend['orders'] as int).toDouble() /
                              maxOrders *
                              150;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                Container(
                                  height: barHeight,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${trend['orders']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  trend['date'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${trend['sales']}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Analytics
            const Text(
              'Detailed Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _buildDetailRow(
                    'Completion Rate',
                    _percent('completedOrders'),
                    Colors.green,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Cancellation Rate',
                    _percent('cancelledOrders'),
                    Colors.red,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Pending Orders',
                    _percent('pendingOrders'),
                    Colors.orange,
                  ),

                  const Divider(),
                  _buildDetailRow(
                    'Ready to Delivery Rate',
                    _percent('ready to delivery'),
                    Colors.lightGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _percent(String key) {
    final total = _analyticsData['totalOrders'] ?? 0;
    final value = _analyticsData[key] ?? 0;
    if (total == 0) return '0.0%';
    return '${((value / total) * 100).toStringAsFixed(1)}%';
  }

  String _averageOrderValue() {
    final total = _analyticsData['totalOrders'] ?? 0;
    final sales = _analyticsData['totalSales'] ?? 0;
    if (total == 0) return '₹0';
    return '₹${(sales / total).toStringAsFixed(0)}';
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
