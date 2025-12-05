import 'package:flutter/material.dart';
import 'product_purchase_page.dart';
import 'dart:convert';
import '../../services/product_service.dart';

class ShopProductsPage extends StatefulWidget {
  final Map<String, dynamic> shop;
  const ShopProductsPage({super.key, required this.shop});

  @override
  State<ShopProductsPage> createState() => _ShopProductsPageState();
}

class _ShopProductsPageState extends State<ShopProductsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> products = [];

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

    if (src.trim().startsWith('data:')) {
      try {
        final parts = src.split(',');
        final b64 = parts.length > 1 ? parts.last : '';
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        );
      }
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
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final shopId = widget.shop['_id'] ?? '';
      if (shopId.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final result = await ProductService.getProducts(ownerId: shopId);

      if (result['success'] == true) {
        final productList = (result['data'] as List? ?? [])
            .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
            .toList();
        setState(() {
          products = productList;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopName = widget.shop['shopName'] ?? widget.shop['name'] ?? 'Shop';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(shopName), elevation: 1),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(shopName), elevation: 1),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine number of columns dynamically based on available width.
          // Aim for ~180px card width; always have at least 2 columns on small screens.
          int cols = (constraints.maxWidth / 180).floor();
          if (cols < 2) cols = 2;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No products available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final name =
                          product['name'] ??
                          product['productName'] ??
                          'Product';
                      final price = (product['price'] ?? 0).toDouble();
                      final mrp = (product['mrp'] ?? price).toDouble();
                      final discount = mrp > price
                          ? ((1 - (price / mrp)) * 100).toInt()
                          : 0;
                      final rating =
                          (product['rating'] ?? product['avgRating'] ?? 0)
                              .toDouble();

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductPurchasePage(
                                  offer: {
                                    '_id': product['_id'],
                                    'productId': product['_id'],
                                    'product': name,
                                    'name': name,
                                    'shop': shopName,
                                    'shopName': shopName,
                                    'price': price.toInt(),
                                    'mrp': mrp.toInt(),
                                    'ownerId': widget.shop['_id'],
                                    'shopId': widget.shop['_id'],
                                    'discount': discount,
                                    'validTill': 'Dec 31, 2025',
                                    'images': product['images'] ?? [],
                                  },
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color: Colors.blue.shade50,
                                    child: _buildImageFromProduct(
                                      product,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 12,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            rating > 0
                                                ? rating.toStringAsFixed(1)
                                                : 'New',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${price.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          if (mrp > price)
                                            Text(
                                              '₹${mrp.toInt()}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (discount > 0) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '$discount% off',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
