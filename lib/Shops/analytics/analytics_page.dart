import 'package:cart_link/Shops/analytics/cancelled_orders_page.dart';
import 'package:cart_link/Shops/analytics/compleated_orders_page.dart';
import 'package:cart_link/Shops/analytics/pending_orders_page.dart';
import 'package:cart_link/Shops/analytics/ready_to_delivery_page.dart';
import 'package:cart_link/Shops/analytics/orders_analytics.dart';
import 'package:flutter/material.dart';
import 'package:cart_link/shared/notification_actions.dart';
import 'package:cart_link/Shops/offer_sales_page.dart';
import 'package:cart_link/theme_data.dart';

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
    'offerTotalSales': 8650,
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
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
        actions: const [NotificationActions()],
      ),
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
                    color: ThemeColors.primary,
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
                    color: ThemeColors.success,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OfferSalesPage()),
                    );
                  },
                  child: _buildStatCard(
                    title: 'Offer Sales',
                    value: '₹${_analyticsData['offerTotalSales']}',
                    icon: Icons.discount,
                    color: ThemeColors.accent,
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
                    color: ThemeColors.error,
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
                    color: ThemeColors.warning,
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
                    color: ThemeColors.accent,
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
                    _buildOrderTrendChart(),
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
                    ThemeColors.success,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Cancellation Rate',
                    _percent('cancelledOrders'),
                    ThemeColors.error,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Pending Orders',
                    _percent('pendingOrders'),
                    ThemeColors.warning,
                  ),

                  const Divider(),
                  _buildDetailRow(
                    'Ready to Delivery Rate',
                    _percent('ready to delivery'),
                    ThemeColors.success,
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

  Widget _buildOrderTrendChart() {
    final trends = _orderTrend;
    if (trends.isEmpty) return const SizedBox.shrink();
    final maxOrders = trends
        .map((t) => (t['orders'] as int))
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(trends.length, (index) {
            final trend = trends[index];
            final orders = (trend['orders'] as int);
            final sales = trend['sales'];
            final barHeight = maxOrders > 0 ? (orders / maxOrders) * 150 : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$orders',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // background guide lines
                      Container(
                        width: 40,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: List.generate(
                            4,
                            (i) => Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.withOpacity(0.12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // actual bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: 40,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ThemeColors.primaryDark,
                              ThemeColors.primary,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trend['date'],
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹$sales',
                    style: const TextStyle(
                      fontSize: 10,
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
    );
  }

  String _percent(String key) {
    final total = _analyticsData['totalOrders'] ?? 0;
    final value = _analyticsData[key] ?? 0;
    if (total == 0) return '0.0%';
    return '${((value / total) * 100).toStringAsFixed(1)}%';
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
