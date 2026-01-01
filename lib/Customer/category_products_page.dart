import 'package:flutter/material.dart';
// import 'dart:convert';
import '../services/product_service.dart';
import '../services/shop_service.dart';
import 'product_purchase_page.dart';
import 'shop_products_page.dart';
import '../theme_data.dart';

class CategoryProductsPage extends StatefulWidget {
  final String category;
  const CategoryProductsPage({super.key, required this.category});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  List<Map<String, dynamic>> _categoryShops = [];
  List<Map<String, dynamic>> _categoryProducts = [];
  bool _loading = true;

  Widget _buildImageFromProduct(
    Map<String, dynamic> product, {
    BoxFit fit = BoxFit.cover,
  }) {
    String? src;
    final imgs = product['images'];
    if (imgs is List && imgs.isNotEmpty) {
      src = imgs.first?.toString() ?? '';
    } else if (product['image'] != null) {
      src = product['image'].toString();
    }

    if (src == null || src.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }

    return Image.network(
      src,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 2; // Small screens (phones)
    } else if (screenWidth < 900) {
      return 3; // Tablets
    } else {
      return 4; // Large screens (desktops)
    }
  }

  Future<void> _loadCategoryData() async {
    try {
      // Fetch shops and products in parallel for faster loading
      final results = await Future.wait([
        ShopService.getAllShops(),
        ProductService.getProducts(),
      ]);

      final shopsResult = results[0];
      final productsResult = results[1];

      if (shopsResult['success'] != true) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final allShops = (shopsResult['data'] as List? ?? []);

      // Filter shops by category
      final filteredShops = allShops.where((shop) {
        final shopCategory = shop['category'] ?? shop['businessType'] ?? 'General';
        return shopCategory.toString() == widget.category;
      }).toList();

      // Get shop IDs for product filtering
      final shopIds = filteredShops
          .map((s) => s['_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (productsResult['data'] != null) {
        final allProducts = (productsResult['data'] as List? ?? [])
            .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
            .toList();

        // Filter products by category shops
        final filteredProducts = allProducts.where((product) {
          final ownerId = product['ownerId'] ?? product['shopId'] ?? '';
          return shopIds.contains(ownerId.toString());
        }).toList();

        // Fetch images for all filtered products in parallel
        final productsWithImages = await Future.wait(
            filteredProducts.map<Future<Map<String, dynamic>>>((product) async {
          try {
            final id = (product['_id'] ?? product['id'] ?? '').toString();
            if (id.isNotEmpty) {
              final imgs = await ProductService.getProductImages(id);
              if (imgs.isNotEmpty) product['images'] = imgs;
            }
          } catch (e) {
            // ignore image fetch issues for now
          }
          return product;
        }));

        if (!mounted) return;
        setState(() {
          _categoryShops = filteredShops
              .map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s))
              .toList();
          _categoryProducts = productsWithImages;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading category data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Products'),
        foregroundColor: ThemeColors.textColorWhite,
        elevation: 1,
        backgroundColor: ThemeColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shops in this category
                  if (_categoryShops.isNotEmpty) ...[
                    const Text(
                      'Shops',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categoryShops.length,
                        itemBuilder: (context, index) {
                          final shop = _categoryShops[index];
                          final shopName =
                              shop['shopName'] ?? shop['name'] ?? 'Shop';
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ShopProductsPage(shop: shop),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '🏪',
                                    style: TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      shopName.toString(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Products in this category
                  const Text(
                    'Products',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_categoryProducts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text('No products in this category'),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getGridCrossAxisCount(context),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 3 / 4,
                      ),
                      itemCount: _categoryProducts.length,
                      itemBuilder: (context, index) {
                        final product = _categoryProducts[index];
                        final name = product['name'] ?? 'Product';
                        final price = product['price'] ?? 0;
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
                            child: Stack(
                              children: [
                                Column(
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
                                        child: _buildImageFromProduct(product,
                                            fit: BoxFit.cover),
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
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹$price',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
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
                                // Stock Out Banner
                                if (product['inStock'] == false)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Transform.rotate(
                                          angle: -0.3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ThemeColors.primary,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'STOCK OUT',
                                              style: TextStyle(
                                                color: ThemeColors.textColorWhite,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
