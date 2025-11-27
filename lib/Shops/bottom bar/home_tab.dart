import 'package:cart_link/Shops/add-product.dart';
import 'package:cart_link/Shops/analytics/analytics_page.dart';
import 'package:cart_link/Shops/create_offer_page.dart';
import 'package:cart_link/Shops/event_offers_page.dart';
import 'package:cart_link/Shops/daily_sales.dart';
import 'package:cart_link/Shops/offered_products_page.dart';
import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  final Function(int) onNavigateToOrders;
  final Function(int) onNavigateToProducts;

  const HomeTab({
    super.key,
    required this.onNavigateToOrders,
    required this.onNavigateToProducts,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            // mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withAlpha(
                          (0.2 * 255).round(),
                        ),
                        child: const Icon(
                          Icons.storefront,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Welcome back!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your store is open and ready for orders',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(
                    icon: Icons.add_box_outlined,
                    label: 'Add\nProduct',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductPage(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.local_shipping_outlined,
                    label: 'Process\nOrders',
                    onTap: () => onNavigateToOrders(2),
                  ),

                  // New quick action: open Create Offer page
                  _buildQuickAction(
                    icon: Icons.post_add,
                    label: 'Create\nOffer',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateOfferPage(),
                        ),
                      );
                    },
                  ),

                  // Event Offers quick action (apply to complete product sets or selected products)
                  _buildQuickAction(
                    icon: Icons.event_available,
                    label: 'Event\nOffers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EventOffersPage(),
                        ),
                      );
                    },
                  ),

                  _buildQuickAction(
                    icon: Icons.insights_outlined,
                    label: 'View\nAnalytics',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnalyticsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Stats Grid
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  final card = _buildStatCard(
                    title: index == 0
                        ? 'Today\'s Sales'
                        : index == 1
                        ? 'Orders'
                        : index == 2
                        ? 'Products'
                        : index == 3
                        ? 'Offered products'
                        : 'Customers',
                    value: index == 0
                        ? '₹12,450'
                        : index == 1
                        ? '24'
                        : index == 2
                        ? '156'
                        : index == 3
                        ? '4'
                        : '1.2K',
                    trend: index == 0
                        ? '+12%'
                        : index == 1
                        ? '+3'
                        : index == 2
                        ? 'Active'
                        : index == 3
                        ? 'Active'
                        : '+5%',
                    icon: index == 0
                        ? Icons.currency_rupee
                        : index == 1
                        ? Icons.shopping_bag_outlined
                        : index == 2
                        ? Icons.inventory_2_outlined
                        : index == 3
                        ? Icons.discount_outlined
                        : Icons.people_outline,
                    color: index == 0
                        ? Colors.green
                        : index == 1
                        ? Colors.orange
                        : index == 2
                        ? Colors.blue
                        : Colors.purple,
                  );
                  if (index == 0) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailySalesPage(),
                          ),
                        );
                      },
                      child: card,
                    );
                  } else if (index == 1) {
                    return InkWell(
                      onTap: () => onNavigateToOrders(2),
                      child: card,
                    );
                  } else if (index == 2) {
                    return InkWell(
                      onTap: () => onNavigateToProducts(1),
                      child: card,
                    );
                  } else if (index == 3) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OfferedProductsPage(),
                          ),
                        );
                      },
                      child: card,
                    );
                  }
                  return card;
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(height: 2);
                },
                itemCount: 5,
              ),
              const SizedBox(height: 24),

              // Recent Orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Orders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => onNavigateToOrders(2),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text('Order #${1001 + index}'),
                    subtitle: Text(
                      '${2 + index} items • ₹${750 + (index * 100)}',
                    ),
                    trailing: _buildStatusChip(
                      index % 2 == 0 ? 'New' : 'Processing',
                    ),
                    onTap: () => onNavigateToOrders(2),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // avoid expanding in unbounded parent
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const Spacer(), // OK in Row (bounded width)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // replace Spacer (was causing error)
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isNew = status == 'New';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isNew ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isNew ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 12,
        ),
      ),
    );
  }
}
