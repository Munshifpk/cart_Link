import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_purchase_page.dart';
import 'shop_products_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    try {
      // Fetch all shops
      final shopsResp = await http
          .get(Uri.parse('http://localhost:5000/api/Shops'))
          .timeout(const Duration(seconds: 10));

      if (shopsResp.statusCode == 200) {
        final shopsData = jsonDecode(shopsResp.body);
        final allShops = (shopsData['data'] as List? ?? []);

        // Filter shops by category
        final filteredShops = allShops.where((shop) {
          final shopCategory =
              shop['category'] ?? shop['businessType'] ?? 'General';
          return shopCategory.toString() == widget.category;
        }).toList();

        // Get shop IDs for product fetching
        final shopIds = filteredShops
            .map((s) => s['_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        // Fetch all products
        final productsResp = await http
            .get(Uri.parse('http://localhost:5000/api/products'))
            .timeout(const Duration(seconds: 10));

        if (productsResp.statusCode == 200) {
          final productsData = jsonDecode(productsResp.body);
          final allProducts = (productsData['data'] as List? ?? [])
              .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
              .toList();

          // Filter products by category shops
          final filteredProducts = allProducts.where((product) {
            final ownerId = product['ownerId'] ?? product['shopId'] ?? '';
            return shopIds.contains(ownerId.toString());
          }).toList();

          setState(() {
            _categoryShops = filteredShops
                .map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s))
                .toList();
            _categoryProducts = filteredProducts;
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      } else {
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
      appBar: AppBar(title: Text('${widget.category} Products'), elevation: 1),
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
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
                                    child: const Center(
                                      child: Icon(
                                        Icons.shopping_bag,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
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
