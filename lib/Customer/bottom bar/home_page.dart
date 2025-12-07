import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../customer_home.dart';
import 'shops_page.dart';
import '../shop_products_page.dart';
import '../product_purchase_page.dart';
import '../category_products_page.dart';
import '../../services/product_service.dart';
import 'package:cart_link/services/auth_state.dart';

class CustomerHomePage extends StatefulWidget {
  final Customer? customer;
  const CustomerHomePage({super.key, this.customer});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _shops = [];
  List<String> _categories = [];
  List<Map<String, dynamic>> _recommendedProducts = [];
  bool _loadingProducts = false;
  List<Map<String, dynamic>> _followingShops = [];
  bool _loadingFollowingShops = false;

  String get _backendBase {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadShops(),
      _loadCategories(),
      _loadRecommendedProducts(),
      _loadFollowingShops(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      final resp = await http
          .get(Uri.parse('$_backendBase/api/Shops'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final shops = (data['data'] as List? ?? []);
        final uniqueCategories = <String>{};
        for (var shop in shops) {
          final category =
              shop['category'] ?? shop['businessType'] ?? 'General';
          uniqueCategories.add(category.toString());
        }
        if (!mounted) return;
        setState(() {
          _categories = uniqueCategories.toList();
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadRecommendedProducts() async {
    try {
      setState(() => _loadingProducts = true);
      final result = await ProductService.getProducts();
      if (result['success'] == true && mounted) {
        var products = (result['data'] as List? ?? [])
            .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
            .toList();

        // Fetch images for each product in parallel (backend excludes images in list)
        products = await Future.wait(products.map<Future<Map<String, dynamic>>>((p) async {
          try {
            final id = (p['_id'] ?? p['id'] ?? '').toString();
            if (id.isNotEmpty) {
              final imgs = await ProductService.getProductImages(id);
              if (imgs.isNotEmpty) p['images'] = imgs;
            }
          } catch (_) {
            // ignore image fetch errors
          }
          return p;
        }));

        // Shuffle and take 8 random products
        products.shuffle();
        final randomProducts = products.take(8).toList();

        // Fetch shops once to map ownerId -> shopName
        try {
          final shopsResp = await http
              .get(Uri.parse('$_backendBase/api/Shops'))
              .timeout(const Duration(seconds: 10));
          if (shopsResp.statusCode == 200) {
            final shopsData = jsonDecode(shopsResp.body);
            final shopsList = (shopsData['data'] as List? ?? [])
                .map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s))
                .toList();
            final Map<String, String> shopNames = {};
            for (var s in shopsList) {
              final id = (s['_id'] ?? s['id'] ?? '').toString();
              final n = (s['shopName'] ?? s['name'] ?? '').toString();
              if (id.isNotEmpty) shopNames[id] = n;
            }
            // assign shopName to products if missing
            for (var p in randomProducts) {
              final ownerId =
                  (p['ownerId'] ?? p['owner'] ?? p['owner_id'] ?? '')
                      .toString();
              if ((p['shopName'] == null || p['shopName'].toString().isEmpty) &&
                  ownerId.isNotEmpty) {
                p['shopName'] = shopNames[ownerId] ?? p['shopName'] ?? 'Shop';
              }
            }
          }
        } catch (_) {
          // ignore shops fetch errors; products keep whatever shopName they have
        }

        setState(() {
          _recommendedProducts = randomProducts;
          _loadingProducts = false;
        });

        // Automatic periodic refresh removed — recommended products set once
      } else {
        setState(() => _loadingProducts = false);
      }
    } catch (e) {
      print('Error loading recommended products: $e');
      setState(() => _loadingProducts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recommended products: $e')),
        );
      }
    }
  }

  Future<void> _loadFollowingShops() async {
    try {
      final customerId = AuthState.currentCustomer?['_id'] as String?;
      if (customerId == null || customerId.isEmpty) {
        setState(() {
          _followingShops = [];
          _loadingFollowingShops = false;
        });
        return;
      }

      setState(() => _loadingFollowingShops = true);

      final uri = Uri.parse('$_backendBase/api/customers/$customerId/following');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final shops = (data['data']?['shops'] as List? ?? [])
            .map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s))
            .toList();

        // fetch product counts per followed shop
        final futures = shops.map((shop) async {
          final shopId = (shop['_id'] ?? shop['id'] ?? '').toString();
          int count = 0;
          if (shopId.isNotEmpty) {
            try {
              final resp2 = await http
                  .get(Uri.parse('$_backendBase/api/products?ownerId=$shopId'))
                  .timeout(const Duration(seconds: 10));
              if (resp2.statusCode == 200) {
                final pData = jsonDecode(resp2.body);
                final products = (pData['data'] as List? ?? []);
                count = products.length;
              }
            } catch (_) {
              count = 0;
            }
          }
          shop['productCount'] = count;
          return shop;
        }).toList();

        final enriched = await Future.wait(futures);
        if (mounted) {
          setState(() {
            _followingShops = enriched;
            _loadingFollowingShops = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _followingShops = [];
            _loadingFollowingShops = false;
          });
        }
      }
    } catch (e) {
      print('Error loading following shops: $e');
      setState(() => _loadingFollowingShops = false);
    }
  }

  Future<void> _loadShops() async {
    try {
      final resp = await http
          .get(Uri.parse('$_backendBase/api/Shops'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = (data['data'] as List? ?? [])
            .map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s))
            .toList();
        // Fetch product counts for each shop in parallel
        final futures = list.map((shop) async {
          final shopId = shop['_id']?.toString() ?? '';
          int count = 0;
          if (shopId.isNotEmpty) {
            try {
              final resp2 = await http
                  .get(Uri.parse('$_backendBase/api/products?ownerId=$shopId'))
                  .timeout(const Duration(seconds: 10));
              if (resp2.statusCode == 200) {
                final pData = jsonDecode(resp2.body);
                final products = (pData['data'] as List? ?? []);
                count = products.length;
              }
            } catch (_) {
              count = 0;
            }
          }
          shop['productCount'] = count;
          return shop;
        }).toList();

        final enriched = await Future.wait(futures);
        // sort by productCount desc and limit to top 6
        enriched.sort(
          (a, b) =>
              (b['productCount'] as int).compareTo(a['productCount'] as int),
        );
        final top = enriched.take(6).toList();
        if (!mounted) return;
        setState(() {
          _shops = top;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildShopCardFromData(Map<String, dynamic> shop) {
    final name = (shop['shopName'] ?? shop['name'] ?? 'Shop').toString();
    final icon = shop['icon'] ?? '🏪';
    final rating = (shop['rating'] ?? 0).toString();
    final count = shop['productCount'] ?? 0;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ShopProductsPage(shop: shop)),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon.toString(), style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '$count products',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  rating,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper: get first image URL/base64 from a product map and render it
  Widget _buildImageForProduct(Map<String, dynamic> product) {
    String? src;
    final imgs = product['images'];
    if (imgs is List && imgs.isNotEmpty) {
      src = imgs.first?.toString() ?? '';
    } else if (product['image'] != null) {
      src = product['image'].toString();
    }

    if (src == null || src.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
      );
    }

    if (src.trim().startsWith('data:')) {
      try {
        final parts = src.split(',');
        final b64 = parts.length > 1 ? parts.last : '';
        final bytes = base64Decode(b64);
        return Center(
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          ),
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        );
      }
    }

    return Center(
      child: Image.network(
        src,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        key: const PageStorageKey('home'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories Section
            const Text(
              'Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 35,
              child: _categories.isEmpty
                  ? const Center(child: Text('No categories available'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CategoryProductsPage(category: category),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Popular Shops Section (moved up)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Shops',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopsPage()),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: List.generate(
                        _shops.isNotEmpty
                            ? (_shops.length < 5 ? _shops.length : 5)
                            : 0,
                        (i) => _buildShopCardFromData(_shops[i]),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recommended Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _loadingProducts
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Dynamic column count based on screen width
                      int cols = 2;
                      if (constraints.maxWidth >= 600) cols = 3;
                      if (constraints.maxWidth >= 900) cols = 4;
                      if (constraints.maxWidth >= 1200) cols = 5;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: _recommendedProducts.length,
                        itemBuilder: (context, index) {
                          final product = _recommendedProducts[index];
                          final name = product['name'] ?? 'Product';
                          final price = product['price'] ?? 0;
                          final mrp =
                              product['mrp'] ?? product['listPrice'] ?? price;
                          final double p = (price is num)
                              ? price.toDouble()
                              : double.tryParse(price.toString()) ?? 0.0;
                          final double m = (mrp is num)
                              ? mrp.toDouble()
                              : double.tryParse(mrp.toString()) ?? p;
                          final int discount = (m > 0 && m > p)
                              ? (((m - p) / m) * 100).round()
                              : 0;
                          final shopName = product['shopName'] ?? 'Shop';
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductPurchasePage(offer: product),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: _buildImageForProduct(product),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name.toString(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              '₹${p.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (m > p)
                                              Text(
                                                '₹${m.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            const Spacer(),
                                            if (discount > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '-${discount}%',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          shopName.toString(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            const SizedBox(height: 24),
            // Following Shops Section (added at bottom)
            const Text(
              'Shops You Follow',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: _loadingFollowingShops
                  ? const Center(child: CircularProgressIndicator())
                  : _followingShops.isEmpty
                  ? Center(
                      child: Text(
                        'You are not following any shops yet.\nTap follow on a shop to see updates here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: List.generate(
                        _followingShops.length,
                        (i) => _buildShopCardFromData(_followingShops[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
