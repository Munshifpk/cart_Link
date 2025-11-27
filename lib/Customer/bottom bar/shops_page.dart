import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../shop_products_page.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> shops = [];
  Map<String, int> productCounts = {}; // Store product count per shop

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/Shops'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shopList = (data['data'] as List? ?? [])
            .map<Map<String, dynamic>>((shop) => Map<String, dynamic>.from(shop))
            .toList();
        
        // Fetch product counts for each shop
        for (var shop in shopList) {
          final shopId = shop['_id'] ?? '';
          if (shopId.isNotEmpty) {
            await _fetchProductCount(shopId);
          }
        }
        
        setState(() {
          shops = shopList;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load shops: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shops: $e')),
        );
      }
    }
  }

  Future<void> _fetchProductCount(String shopId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/products?ownerId=$shopId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['data'] as List? ?? [];
        setState(() {
          productCounts[shopId] = products.length;
        });
      }
    } catch (e) {
      // Silently fail for product count
      print('Error fetching product count for shop $shopId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Popular Shops'), elevation: 1),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (shops.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Popular Shops'), elevation: 1),
        body: const Center(child: Text('No shops available')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Popular Shops'), elevation: 1),
      body: ListView.builder(
        key: const PageStorageKey('shops_list'),
        padding: const EdgeInsets.all(12),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];
          final shopName = shop['shopName'] ?? shop['name'] ?? 'Shop';
          final shopId = shop['_id'] ?? shop['id'] ?? '';
          final rating = (shop['rating'] ?? 4.5).toDouble();
          final reviews = shop['reviews'] ?? 0;

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
                          child: const Center(
                            child: Text(
                              '🏪',
                              style: TextStyle(fontSize: 32),
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
                                shopName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shop['category'] ?? 'General',
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
                                    '$rating ($reviews reviews)',
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
                      shop['description'] ?? 'Visit this shop',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Product preview
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(
                          '${productCounts[shopId] ?? 0} products',
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