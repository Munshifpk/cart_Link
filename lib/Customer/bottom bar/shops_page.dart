import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../shop_products_page.dart';
import '../../theme_data.dart';
import 'package:cart_link/services/auth_state.dart';
import 'package:cart_link/constant.dart';

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

  @override
  void initState() {
    super.initState();
    _loadShops();
    _loadFollowedShops();
  }

  Future<void> _loadFollowedShops() async {
    try {
      final customerId = AuthState.currentCustomer?['_id'] as String?;
      if (customerId == null || customerId.isEmpty) {
        return;
      }

      final uri = backendUri('$kApiCustomers/$customerId/following');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final ids = ((data['data']?['following'] as List?) ?? [])
            .map((e) => e.toString())
            .toSet();
        if (mounted) {
          setState(() {
            followedShops = ids;
          });
        }
      }
    } catch (_) {
      // ignore errors; fallback to empty set
    }
  }

  Future<void> _toggleFollowShop(String shopId, String shopName) async {
    try {
      // Get customer ID from auth state
      final customerId = AuthState.currentCustomer?['_id'] as String?;
      
      if (customerId == null || customerId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to follow shops'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final isCurrentlyFollowing = followedShops.contains(shopId);
      
      // Optimistic UI update
      setState(() {
        if (isCurrentlyFollowing) {
          followedShops.remove(shopId);
        } else {
          followedShops.add(shopId);
        }
      });

      final isNowFollowing = followedShops.contains(shopId);

      // Call backend to update customer's following list and shop's followers list
      final uri = backendUri('$kApiCustomers/follow-shop');
      
      try {
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'customerId': customerId,
            'shopId': shopId,
            'shopName': shopName,
            'isFollowing': isNowFollowing,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Success - UI already updated optimistically
          if (mounted) {
            final message = isNowFollowing
                ? 'Following $shopName'
                : 'Unfollowed $shopName';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Revert the UI change if the API call failed
          setState(() {
            if (isCurrentlyFollowing) {
              followedShops.add(shopId);
            } else {
              followedShops.remove(shopId);
            }
          });
        }
      } catch (e) {
        // Network error - revert the UI change
        setState(() {
          if (isCurrentlyFollowing) {
            followedShops.add(shopId);
          } else {
            followedShops.remove(shopId);
          }
        });
      }
    } catch (e) {
      // ignore error
    }
  }

  Future<void> _loadShops() async {
    try {
        final response = await http
          .get(backendUri(kApiShops))
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
          .get(backendUri(kApiProducts, queryParameters: {'ownerId': shopId}))
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (shops.isEmpty) {
      return Scaffold(
        body: const Center(child: Text('No shops available')),
      );
    }

    return Scaffold(
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
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: ThemeColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [ThemeColors.cardShadow],
              ),
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
                            color: ThemeColors.primary.withOpacity(0.08),
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
                                  : Colors.blue,
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
                                color: ThemeColors.primaryDark,
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
            ),
          );
        },
      ),
    );
  }
}
