import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../theme_data.dart';
import '../services/shop_service.dart';

class ProductAdminPage extends StatefulWidget {
  const ProductAdminPage({super.key});

  @override
  State<ProductAdminPage> createState() => _ProductAdminPageState();
}

class ProductItem {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String shopName;
  final String description;
  final String? imageUrl;
  final DateTime? createdAt;

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.shopName,
    required this.description,
    required this.imageUrl,
    this.createdAt,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    String shopName = '';
    final shop = json['shop'];
    if (shop is Map) {
      shopName = shop['shopName'] ?? shop['name'] ?? '';
    } else if (json['shopName'] != null) {
      shopName = json['shopName'];
    } else if (shop is String) {
      shopName = shop;
    }

    final images = json['images'];
    String? image;
    if (images is List && images.isNotEmpty) image = images.first.toString();

    return ProductItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['productName'] ?? 'Unnamed product',
      price: (json['price'] ?? 0).toDouble(),
      stock: (json['stock'] ?? json['quantity'] ?? 0).toInt(),
      shopName: shopName,
      description: json['description'] ?? '',
      imageUrl: image,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class _ProductAdminPageState extends State<ProductAdminPage> {
  bool _loading = true;
  List<ProductItem> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final res = await ProductService.getProducts();
      if (res['success'] == true) {
        var data = res['data'] ?? [];

        // Fetch images for each product
        data = await Future.wait((data as List).map<Future<Map<String, dynamic>>>((json) async {
          final Map<String, dynamic> map = Map<String, dynamic>.from(json as Map);
          try {
            final id = (map['_id'] ?? map['id'] ?? '').toString();
            if (id.isNotEmpty) {
              final imgs = await ProductService.getProductImages(id);
              if (imgs.isNotEmpty) map['images'] = imgs;
            }
          } catch (_) {}
          return map;
        }));

        // fetch shops once and build id->name map to resolve shop names
        final shopsRes = await ShopService.getAllShops();
        Map<String, String> shopNames = {};
        if (shopsRes['success'] == true) {
          final List<dynamic> shops = shopsRes['data'] ?? [];
          for (final s in shops) {
            if (s is Map && (s['_id'] != null || s['id'] != null)) {
              final id = (s['_id'] ?? s['id']).toString();
              final name = (s['shopName'] ?? s['name'] ?? '').toString();
              shopNames[id] = name;
            }
          }
        }

        setState(() {
          _products = (data as List).map((e) {
            final Map<String, dynamic> js = Map<String, dynamic>.from(e as Map);

            // attempt to extract shopName directly from product JSON
            String resolvedShop = '';
            final shopField = js['shop'];
            if (shopField is Map) {
              resolvedShop = (shopField['shopName'] ?? shopField['name'] ?? '').toString();
            } else if (shopField is String) {
              resolvedShop = shopNames[shopField] ?? shopField;
            }

            // fallback keys commonly used
            if (resolvedShop.isEmpty) {
              final ownerId = js['ownerId'] ?? js['owner'] ?? js['shopId'] ?? js['sellerId'];
              if (ownerId != null) {
                final id = ownerId is Map ? (ownerId['_id'] ?? ownerId['id'])?.toString() ?? '' : ownerId.toString();
                if (id.isNotEmpty) resolvedShop = shopNames[id] ?? '';
              }
            }

            final item = ProductItem.fromJson(js);
            // override shopName if we resolved one
            if (resolvedShop.isNotEmpty) {
              return ProductItem(
                id: item.id,
                name: item.name,
                price: item.price,
                stock: item.stock,
                shopName: resolvedShop,
                description: item.description,
                imageUrl: item.imageUrl,
                createdAt: item.createdAt,
              );
            }

            return item;
          }).toList();
        });
      } else {
        _showError('Failed to load products', res['message'] ?? 'Unknown error');
      }
    } catch (e) {
      _showError('Error', e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String title, String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showInfo(ProductItem p) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Image.network(p.imageUrl!, height: 120, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
                ),
              Text('ID: ${p.id}'),
              const SizedBox(height: 6),
              Text('Shop: ${p.shopName.isNotEmpty ? p.shopName : '—'}'),
              const SizedBox(height: 6),
              Text('Price: ₹${p.price.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              Text('Stock: ${p.stock}'),
              const SizedBox(height: 6),
              if (p.createdAt != null) Text('Created: ${p.createdAt}'),
              const SizedBox(height: 8),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(p.description.isNotEmpty ? p.description : '—'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products (Admin)'), backgroundColor: ThemeColors.primary, foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(ThemeColors.primary),
                      headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      dataTextStyle: const TextStyle(color: Colors.black87),
                      columnSpacing: 20,
                      headingRowHeight: 56,
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 64,
                      columns: const [
                        DataColumn(label: Text('Si.No')),
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Shop')),
                        DataColumn(label: Text('Price'), numeric: true),
                        DataColumn(label: Text('Stock'), numeric: true),
                        DataColumn(label: Text('Info')),
                      ],
                      rows: List.generate(_products.length, (i) {
                        final p = _products[i];
                        return DataRow(cells: [
                          DataCell(Text((i + 1).toString())),
                          DataCell(SizedBox(width: 220, child: Text(p.name))),
                          DataCell(Text(p.shopName.isNotEmpty ? p.shopName : '—')),
                          DataCell(Container(alignment: Alignment.centerRight, child: Text('₹${p.price.toStringAsFixed(2)}'))),
                          DataCell(Container(alignment: Alignment.centerRight, child: Text(p.stock.toString()))),
                          DataCell(IconButton(icon: const Icon(Icons.info_outline, color: Colors.blue), onPressed: () => _showInfo(p))),
                        ]);
                      }),
                    ),
                  ),
                ),
              );
            }),
    );
  }
}
