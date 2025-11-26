import 'package:flutter/material.dart';
import '../customer_home.dart';
import 'shop_carts_page.dart';

class CustomerCartPage extends StatefulWidget {
  final Customer? customer;
  const CustomerCartPage({super.key, this.customer});

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  // Shop-wise cart: Map<shopName, List<cartItems>>
  final Map<String, List<Map<String, dynamic>>> _shopCarts = {};

  @override
  void initState() {
    super.initState();
    _initializeSampleCarts();
  }

  void _initializeSampleCarts() {
    // Sample shops
    _shopCarts['TechZone'] = [];
    _shopCarts['SoundMart'] = [];
    _shopCarts['GadgetHub'] = [];
    _shopCarts['ExampleShop1'] = [];
    _shopCarts['ExampleShop2'] = [];
  }

  void addToCart(String shopName, Map<String, dynamic> product) {
    setState(() {
      if (!_shopCarts.containsKey(shopName)) {
        _shopCarts[shopName] = [];
      }
      _shopCarts[shopName]!.add(product);
    });
  }

  int getTotalItemsInCart() {
    int total = 0;
    _shopCarts.forEach((_, items) => total += items.length);
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final shopsWithItems = _shopCarts.entries
        .where((e) => e.value.isNotEmpty)
        .toList();

    return ListView(
      key: const PageStorageKey('cart'),
      padding: const EdgeInsets.all(12),
      children: [
        if (shopsWithItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cart (${getTotalItemsInCart()} items)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...shopsWithItems.map((shopEntry) {
                final shopName = shopEntry.key;
                final items = shopEntry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.store, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${items.length} item(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 0),
                      ...items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['product'] ?? 'Product',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${item['price']} × ${item['quantity'] ?? 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _shopCarts[shopName]!.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ShopCartsPage(shopName: shopName),
                                    ),
                                  );
                                },
                                child: const Text('View Shop Cart'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
      ],
    );
  }
}
