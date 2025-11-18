import 'package:flutter/material.dart';
import 'shops_admin.dart';
import 'orders_admin.dart';
import 'users_admin.dart';
import 'admin_theme.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // Use shared admin theme colors
  static final Color _kPrimary = AdminTheme.primary;
  static final Color _kAccent = AdminTheme.accent;

  void _openSection(String name) {
    if (name == 'Shops') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShopsAdmin()),
      );
      return;
    }

    if (name == 'Users') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UsersAdmin()),
      );
      return;
    }

    if (name == 'Orders') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdersAdmin()),
      );
      return;
    }

    // Fallback: show a simple placeholder page for other sections
    final pagename = ('$name Admin');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(pagename)),
          body: Center(child: Text('$name - coming soon')),
        ),
      ),
    );
  }

  Widget _buildCard(IconData icon, String title, Color color) {
    // Cards now use a filled gradient background for an attractive look
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSection(title),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cardItems = [
      {'icon': Icons.storefront, 'title': 'Shops'},
      {'icon': Icons.shopping_cart, 'title': 'Orders'},
      {'icon': Icons.people, 'title': 'Users'},
      {'icon': Icons.bar_chart, 'title': 'Analytics'},
      {'icon': Icons.settings, 'title': 'Settings'},
      {'icon': Icons.message, 'title': 'Announcements'},
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AdminTheme.primary,
      ),
      backgroundColor: AdminTheme.scaffoldBackground,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                // Fixed 3 columns to produce 2 rows x 3 columns for 6 items
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: List.generate(cardItems.length, (i) {
                  final item = cardItems[i];
                  final color = (i % 2 == 0) ? _kPrimary : _kAccent;
                  return _buildCard(
                    item['icon'] as IconData,
                    item['title'] as String,
                    color,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
