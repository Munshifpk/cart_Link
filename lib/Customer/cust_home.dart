import 'package:cart_link/main.dart';
import 'package:flutter/material.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    _HomePage(),
    _CategoryPage(),
    _CartPage(),
    _ProfilePage(),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        backgroundColor: Colors.blue,
        toolbarHeight: 72,
        centerTitle: false,
        elevation: 2,
      ),

      // Move previous "app bar" elements here, below the AppBar
      body: Column(
        children: [
          // top controls (location, search, notifications)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Location
                  InkWell(
                    onTap: () {
                      // TODO: open location picker
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.location_on, color: Colors.deepOrange),
                        SizedBox(width: 6),
                        Text('Your Location', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),

                  // Search bar (expanded centered)
                  Expanded(
                    child: Center(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Search for products, brands...',
                                ),
                                onSubmitted: (q) {
                                  // TODO: perform search
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Notification button
                  const SizedBox(width: 12),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          // TODO: open notifications
                        },
                        icon: const Icon(Icons.notifications_none),
                      ),
                      // small badge
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Main pages area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                final inAnim = Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: inAnim, child: child),
                );
              },
              child: SizedBox(
                key: ValueKey<int>(_currentIndex),
                width: double.infinity,
                height: double.infinity,
                child: _pages[_currentIndex],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Placeholder pages - replace with real implementations
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('home'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Promo banner / carousel')),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recommended',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3 / 2,
            ),
            itemCount: 4,
            itemBuilder: (context, i) => Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('Item ${i + 1}')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPage extends StatelessWidget {
  const _CategoryPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('category'),
      padding: const EdgeInsets.all(16),
      children: List.generate(
        8,
        (i) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text('Category ${i + 1}'),
            subtitle: const Text('Tap to view'),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}

class _CartPage extends StatelessWidget {
  const _CartPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const PageStorageKey('cart'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          const Text('Your cart is empty', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => {}, child: const Text('Shop now')),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('profile'),
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 48)),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'John Doe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            title: const Text('Orders'),
            leading: const Icon(Icons.list),
            onTap: () {},
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Settings'),
            leading: const Icon(Icons.settings),
            onTap: () {},
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
        ),
      ],
    );
  }
}
