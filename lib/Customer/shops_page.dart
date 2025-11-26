import 'package:flutter/material.dart';
import 'shop_products_page.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  // Example shops
  final List<Map<String, dynamic>> shops = [
    {
      'id': 1,
      'name': 'TechZone',
      'category': 'Electronics',
      'rating': 4.8,
      'reviews': 1250,
      'icon': '📱',
      'description': 'Premium electronics and gadgets',
      'products': [
        {
          'name': 'Wireless Earbuds',
          'price': 2499,
          'mrp': 4999,
          'image': '🎧',
          'rating': 4.5,
        },
        {
          'name': 'USB-C Cable',
          'price': 299,
          'mrp': 599,
          'image': '🔌',
          'rating': 4.7,
        },
        {
          'name': 'Phone Stand',
          'price': 399,
          'mrp': 899,
          'image': '📱',
          'rating': 4.6,
        },
        {
          'name': 'Screen Protector',
          'price': 199,
          'mrp': 499,
          'image': '🛡️',
          'rating': 4.4,
        },
      ],
    },
    {
      'id': 2,
      'name': 'SoundMart',
      'category': 'Audio',
      'rating': 4.6,
      'reviews': 890,
      'icon': '🔊',
      'description': 'High-quality audio equipment',
      'products': [
        {
          'name': 'Bluetooth Speaker',
          'price': 1999,
          'mrp': 3999,
          'image': '🔊',
          'rating': 4.7,
        },
        {
          'name': 'Headphones',
          'price': 3499,
          'mrp': 6999,
          'image': '🎧',
          'rating': 4.8,
        },
        {
          'name': 'Audio Cable',
          'price': 249,
          'mrp': 549,
          'image': '🔌',
          'rating': 4.3,
        },
        {
          'name': 'Microphone',
          'price': 2999,
          'mrp': 5999,
          'image': '🎤',
          'rating': 4.6,
        },
      ],
    },
    {
      'id': 3,
      'name': 'GadgetHub',
      'category': 'Smart Devices',
      'rating': 4.7,
      'reviews': 2100,
      'icon': '⌚',
      'description': 'Smart devices and wearables',
      'products': [
        {
          'name': 'Smart Watch',
          'price': 4999,
          'mrp': 9999,
          'image': '⌚',
          'rating': 4.7,
        },
        {
          'name': 'Fitness Band',
          'price': 1999,
          'mrp': 3999,
          'image': '📊',
          'rating': 4.5,
        },
        {
          'name': 'Smart Ring',
          'price': 2999,
          'mrp': 5999,
          'image': '💍',
          'rating': 4.6,
        },
        {
          'name': 'Portable Charger',
          'price': 899,
          'mrp': 1999,
          'image': '🔋',
          'rating': 4.8,
        },
      ],
    },
    {
      'id': 4,
      'name': 'PhotoPro',
      'category': 'Photography',
      'rating': 4.9,
      'reviews': 567,
      'icon': '📷',
      'description': 'Professional photography gear',
      'products': [
        {
          'name': 'Camera Lens',
          'price': 8999,
          'mrp': 14999,
          'image': '📷',
          'rating': 4.9,
        },
        {
          'name': 'Tripod Stand',
          'price': 1499,
          'mrp': 2999,
          'image': '📸',
          'rating': 4.6,
        },
        {
          'name': 'Ring Light',
          'price': 2499,
          'mrp': 4999,
          'image': '💡',
          'rating': 4.7,
        },
        {
          'name': 'Camera Bag',
          'price': 1999,
          'mrp': 3999,
          'image': '👜',
          'rating': 4.5,
        },
      ],
    },
    {
      'id': 5,
      'name': 'AccessoryHub',
      'category': 'Accessories',
      'rating': 4.5,
      'reviews': 3450,
      'icon': '🎒',
      'description': 'Phone and laptop accessories',
      'products': [
        {
          'name': 'Phone Case',
          'price': 399,
          'mrp': 999,
          'image': '📱',
          'rating': 4.6,
        },
        {
          'name': 'Laptop Bag',
          'price': 1299,
          'mrp': 2499,
          'image': '🎒',
          'rating': 4.7,
        },
        {
          'name': 'Mouse Pad',
          'price': 249,
          'mrp': 599,
          'image': '🖱️',
          'rating': 4.4,
        },
        {
          'name': 'Keyboard',
          'price': 1999,
          'mrp': 3999,
          'image': '⌨️',
          'rating': 4.8,
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popular Shops'), elevation: 1),
      body: ListView.builder(
        key: const PageStorageKey('shops_list'),
        padding: const EdgeInsets.all(12),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopProductsPage(shop: shop),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop header with icon and basic info
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Shop icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              shop['icon'] ?? '🏪',
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Shop name and category
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop['name'] ?? 'Shop',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shop['category'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${shop['rating']} (${shop['reviews']} reviews)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Arrow indicator
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  const Divider(height: 0),
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      shop['description'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Product preview (showing first 4 products)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(
                          '${(shop['products'] as List?)?.length ?? 0} products',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShopProductsPage(shop: shop),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag, size: 16),
                          label: const Text('Browse'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
