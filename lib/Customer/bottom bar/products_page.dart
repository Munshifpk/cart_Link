import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../theme_data.dart';

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
      setState(() {
        _products = data.map((e) => e as Map<String, dynamic>).toList();
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
        : LayoutBuilder(builder: (context, constraints) {
            final cols = _columnsForWidth(constraints.maxWidth);
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                key: const PageStorageKey('products_grid'),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final p = _products[index];
                  final name = (p['name'] ?? p['productName'] ?? '').toString();
                  final shopName = () {
                    final shop = p['shop'];
                    if (shop is Map) return (shop['shopName'] ?? shop['name'] ?? '').toString();
                    return (p['shopName'] ?? '').toString();
                  }();
                  final price = (p['price'] ?? 0).toDouble();
                  final mrp = (p['mrp'] ?? p['listPrice'] ?? price).toDouble();
                  final rating = (p['rating'] ?? p['avgRating'] ?? 0).toDouble();
                  final image = () {
                    final imgs = p['images'];
                    if (imgs is List && imgs.isNotEmpty) return imgs.first.toString();
                    if (p['image'] != null) return p['image'].toString();
                    return ''; 
                  }();

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: InkWell(
                      onTap: () {},
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // image area
                          AspectRatio(
                            aspectRatio: 16 / 10,
                            child: image.isNotEmpty
                                ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(index))
                                : _placeholder(index),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _buildRating(rating),
                                    const SizedBox(width: 8),
                                    Text(rating > 0 ? rating.toStringAsFixed(1) : 'New', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (mrp > price)
                                      Text('₹${mrp.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                                    if (mrp > price) const SizedBox(width: 8),
                                    Text('₹${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(shopName.isNotEmpty ? shopName : '—', style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
          });
  }

  Widget _placeholder(int index) {
    final color = ThemeColors.primary.withOpacity(0.08);
    return Container(
      color: color,
      child: Center(child: Icon(Icons.image, color: ThemeColors.primary.withOpacity(0.6))),
    );
  }

  Widget _buildRating(double r) {
    final full = r.floor();
    final half = (r - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) return const Icon(Icons.star, color: Colors.amber, size: 14);
        if (i == full && half) return const Icon(Icons.star_half, color: Colors.amber, size: 14);
        return const Icon(Icons.star_border, color: Colors.amber, size: 14);
      }),
    );
  }
}
