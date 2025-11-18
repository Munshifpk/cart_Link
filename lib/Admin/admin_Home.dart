import 'package:flutter/material.dart';
import 'shops_admin.dart';
import 'orders_admin.dart';
import 'users_admin.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openSection(title),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
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
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildCard(
                    Icons.storefront,
                    'Shops',
                    const Color(0xFF0D47A1),
                  ),
                  _buildCard(
                    Icons.shopping_cart,
                    'Orders',
                    const Color(0xFF1E88E5),
                  ),
                  _buildCard(Icons.people, 'Users', const Color(0xFFFFA500)),
                  _buildCard(
                    Icons.bar_chart,
                    'Analytics',
                    const Color(0xFF43A047),
                  ),
                  _buildCard(Icons.settings, 'Settings', Colors.grey),
                  _buildCard(
                    Icons.message,
                    'Announcements',
                    const Color(0xFFE64A19),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
