import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../shop_products_page.dart';
import '../../theme_data.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> shops = [];
  Map<String, int> productCounts = {}; // Store product count per shop
  Set<String> followedShops = {}; // Track followed shops by ID

  String get _backendBase {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  @override
  void initState() {
    super.initState();
    _loadFollowedShops();
    _loadShops();
  }

  Future<void> _loadFollowedShops() async {
    // Load followed shops from backend or local storage
  }

  Future<void> _toggleFollowShop(String shopId, String shopName) async {
    try {
      setState(() {
        if (followedShops.contains(shopId)) {
          followedShops.remove(shopId);
        } else {
          followedShops.add(shopId);
        }
      });

      final uri = Uri.parse('$_backendBase/api/customers/follow-shop');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'shopId': shopId,
          'isFollowing': followedShops.contains(shopId),
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              followedShops.contains(shopId)
                  ? 'Following $shopName - You\'ll get offers & stock updates'
                  : 'Unfollowed $shopName',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _loadShops() async {
    try {
      final response = await http
          .get(Uri.parse('$_backendBase/api/Shops'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shopList = (data['data'] as List? ?? [])
            .map<Map<String, dynamic>>(
              (shop) => Map<String, dynamic>.from(shop),
            )
            .toList();

        // Fetch product counts for each shop in parallel (non-blocking)
        if (mounted) {
          setState(() {
            shops = shopList;
            _loading = false;
          });
        }

        // Fetch product counts in background (don't wait)
        for (var shop in shopList) {
          final shopId = shop['_id'] ?? '';
          if (shopId.isNotEmpty) {
            _fetchProductCount(shopId);
          }
        }
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load shops: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading shops: $e')));
      }
    }
  }

  Future<void> _fetchProductCount(String shopId) async {
    try {
      final response = await http
          .get(Uri.parse('$_backendBase/api/products?ownerId=$shopId'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['data'] as List? ?? [];
        if (mounted) {
          setState(() {
            productCounts[shopId] = products.length;
          });
        }
      }
    } catch (e) {
      // Silently fail for product count - set to 0 or skip
      if (mounted) {
        setState(() {
          productCounts[shopId] = 0;
        });
      }
      // ignore: avoid_print
      print('⚠ Error fetching product count for shop $shopId: $e');
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
                            child: Text('🏪', style: TextStyle(fontSize: 32)),
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
                        // Follow button moved to top-right of the card
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _toggleFollowShop(shopId, shopName),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: followedShops.contains(shopId)
                                    ? ThemeColors.greenButton
                                    : ThemeColors.primary,
                                foregroundColor: followedShops.contains(shopId)
                                    ? ThemeColors.textColorWhite
                                    : ThemeColors.textColorWhite,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              icon: Icon(
                                followedShops.contains(shopId)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                              ),
                              label: Text(
                                followedShops.contains(shopId)
                                    ? 'Following'
                                    : 'Follow',
                                style: const TextStyle(fontSize: 12),
                              
                              ),
                              
                            ),
                            const SizedBox(height: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            
                          ],
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
                  // Product preview and follow button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                          ],
                        ),
                        const SizedBox(height: 8),
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
