import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../theme_data.dart';
import 'dart:convert';
import '../product_purchase_page.dart';

class CustomerProductsPage extends StatefulWidget {
  const CustomerProductsPage({super.key});

  @override
  State<CustomerProductsPage> createState() => _CustomerProductsPageState();
}

class _CustomerProductsPageState extends State<CustomerProductsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final res = await ProductService.getProducts();
    if (res['success'] == true) {
      final List<dynamic> data = res['data'] ?? [];
      // sanitize incoming data: convert possible JS interop objects to plain Dart types
      final sanitized = data.map<Map<String, dynamic>>((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        // normalize images to list of strings
        final imgs = m['images'];
        if (imgs is Iterable) {
          m['images'] = imgs.map((x) => x == null ? '' : x.toString()).toList();
        }
        // normalize shop to a map of strings
        final shop = m['shop'];
        if (shop is Map) {
          try {
            m['shop'] = Map<String, dynamic>.from(
              shop.map((k, v) => MapEntry(k.toString(), v)),
            );
          } catch (_) {
            m['shop'] = {'name': shop.toString()};
          }
        }
        return m;
      }).toList();

      setState(() {
        _products = sanitized;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to load products')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  int _columnsForWidth(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              final cols = _columnsForWidth(constraints.maxWidth);
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  key: const PageStorageKey('products_grid'),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final p = _products[index];
                    final name = (p['name'] ?? p['productName'] ?? '')
                        .toString();
                    final shopName = () {
                      final shop = p['shop'];
                      if (shop is Map) {
                        return (shop['shopName'] ?? shop['name'] ?? '')
                            .toString();
                      }
                      return (p['shopName'] ?? '').toString();
                    }();
                    final price = (p['price'] ?? 0).toDouble();
                    final mrp = (p['mrp'] ?? p['listPrice'] ?? price)
                        .toDouble();
                    final rating = (p['rating'] ?? p['avgRating'] ?? 0)
                        .toDouble();
                    final imagesList = () {
                      final imgs = p['images'];
                      if (imgs is List && imgs.isNotEmpty) {
                        return imgs.map((e) => e.toString()).toList();
                      }
                      if (p['image'] != null) return [p['image'].toString()];
                      return <String>[];
                    }();

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
                                  'product': name,
                                  'shop': shopName,
                                  'price': price.toInt(),
                                  'discount': ((1 - (price / mrp)) * 100)
                                      .toInt(),
                                  'validTill': 'Dec 31, 2025',
                                },
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // image area (~75% of card) with multiple-image support
                            Expanded(
                              flex: 3,
                              child: AspectRatio(
                                aspectRatio: 1.1,
                                child: imagesList.isNotEmpty
                                    ? _buildImageFromSource(
                                        imagesList[0],
                                        index,
                                      )
                                    : _placeholder(index),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        _buildRating(rating),
                                        const SizedBox(width: 2),
                                        Text(
                                          rating > 0
                                              ? rating.toStringAsFixed(1)
                                              : 'New',
                                          style: const TextStyle(fontSize: 9),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (mrp > price)
                                          Text(
                                            '₹${mrp.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey,
                                              fontSize: 9,
                                            ),
                                          ),
                                        if (mrp > price)
                                          const SizedBox(width: 2),
                                        Text(
                                          '₹${price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      shopName.isNotEmpty ? shopName : '—',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 8,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
          );
  }

  Widget _placeholder(int index) {
    final col = ThemeColors.primary;
    final color = col.withValues(alpha: 0.08);
    return Container(
      color: color,
      child: Center(
        child: Icon(Icons.image, color: col.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildImageFromSource(
    String src,
    int index, {
    BoxFit fit = BoxFit.cover,
  }) {
    if (src.trim().startsWith('data:')) {
      try {
        final parts = src.split(',');
        final b64 = parts.length > 1 ? parts.last : '';
        final bytes = base64Decode(b64);
        return Center(
          child: Image.memory(bytes, fit: fit, alignment: Alignment.center),
        );
      } catch (_) {
        return _placeholder(index);
      }
    }
    return Center(
      child: Image.network(
        src,
        fit: fit,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => _placeholder(index),
      ),
    );
  }

  Widget _buildRating(double r) {
    final full = r.floor();
    final half = (r - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) {
          return const Icon(Icons.star, color: Colors.amber, size: 14);
        }
        if (i == full && half) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 14);
        }
        return const Icon(Icons.star_border, color: Colors.amber, size: 14);
      }),
    );
  }
}
