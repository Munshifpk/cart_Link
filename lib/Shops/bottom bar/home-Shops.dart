import 'package:flutter/material.dart';
import '../add-product.dart';
import '../settings.dart';
import '../nottification.dart';
import 'home_tab.dart';
import 'products_tab.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';

class ShopHomePage extends StatefulWidget {
  const ShopHomePage({super.key});

  @override
  State<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  int _currentIndex = 0;
  late Function() _refreshProducts;

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Owner Dashboard'
              : _currentIndex == 1
              ? 'Products'
              : _currentIndex == 2
              ? 'Orders'
              : 'Profile',
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: _refreshProducts,
            ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
            ),
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopSettingsPage()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),

      // Show FAB only when Products tab is active (index 1)
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductPage()),
                );
              },
              label: const Text('Add Product'),
              icon: const Icon(Icons.add_business_outlined),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onPageChanged,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0D47A1),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(
            onNavigateToOrders: (index) {
              _onPageChanged(index);
            },
            onNavigateToProducts: (index) {
              _onPageChanged(index);
            },
          ),
          ProductsTab(
            onRefreshCallback: (refreshFn) {
              _refreshProducts = refreshFn;
            },
          ),
          const OrdersTab(),
          const ProfileTab(),
        ],
      ),
    );
  }
}
