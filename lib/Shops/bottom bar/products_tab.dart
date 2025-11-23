import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/auth_state.dart'; // added
import '../../theme_data.dart';

class Product {
  final String id;
  final String name;
  final int stock;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unnamed Product',
      stock: (json['stock'] ?? 0).toInt(),
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }
}

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    // Ensure only the logged-in owner sees products
    final owner = AuthState.currentOwner;
    if (owner == null) {
      // no owner logged in -> return empty list (or you can throw / show message)
      return [];
    }

    final ownerId = owner['_id']?.toString() ?? owner['id']?.toString();
    if (ownerId == null) return [];

    final result = await ProductService.getProducts(ownerId: ownerId);
    if (result['success'] == true) {
      final List<dynamic> productData = result['data'];
      return productData.map((json) => Product.fromJson(json)).toList();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load products'),
            backgroundColor: Colors.red,
          ),
        );
      }
      throw Exception('Failed to load products');
    }
  }

  void _refreshProducts() {
    setState(() => _productsFuture = _fetchProducts());
  }

  void _editProduct(Product product) {
    // TODO: Implement navigation to an edit product page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${product.name}')),
    );
  }

  void _deleteProduct(Product product) {
    // Confirm and delete
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ProductService.deleteProduct(product.id);
              if (!mounted) return;

              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} deleted successfully')),
                );
                _refreshProducts();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(result['message'] ?? 'Failed to delete'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProductInfo(Product product) {
    // TODO: Implement navigation to a product details page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Showing info for ${product.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No products found.'));
        }

        final products = snapshot.data!;

        // Container with AppBar-like headers and a responsive table that fills available space
        return Container(
          // color: ThemeColors.scaffoldBackground,
          child: Column(
            children: [
              // // Header bar (appears like an AppBar for the table)
              // ),

              // Table area fills remaining space and scrolls when needed
              Expanded(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: ThemeColors.primary,
                                secondary: ThemeColors.accent,
                              ),
                          // dataTableTheme: DataTableThemeData(
                          //   headingRowColor: WidgetStateProperty.all(ThemeColors.primary.withOpacity(0.08)),
                          //   headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color:Colors.white),
                          //   dataRowColor: WidgetStateProperty.resolveWith((states) => Colors.white),
                          //   dataTextStyle: const TextStyle(color: Colors.black87),
                          //   dividerThickness: 1,
                          //   headingRowHeight: 56,
                          //   dataRowHeight: 52,
                          //   columnSpacing: 24,
                          // ),
                        ),
                        child: DataTable(
                          headingRowHeight: 56,
                          headingRowColor: WidgetStateProperty.all(ThemeColors.primary),
                          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color:Colors.white),
                          dataTextStyle: const TextStyle(color: Colors.black87),
                          dataRowHeight: 52,
                          columnSpacing: 24,
                          dividerThickness: 1,
                        
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Available Stock'), numeric: true),
                            DataColumn(label: Text('Price'), numeric: true),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: products.map((product) {
                            return DataRow(
                              cells: [
                                DataCell(SizedBox(width: 200, child: Text(product.name))),
                                DataCell(Container(alignment: Alignment.centerRight, child: Text(product.stock.toString()))),
                                DataCell(Container(alignment: Alignment.centerRight, child: Text('₹${product.price.toStringAsFixed(0)}'))),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: ThemeColors.primary),
                                        tooltip: 'Edit',
                                        onPressed: () => _editProduct(product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        tooltip: 'Delete',
                                        onPressed: () => _deleteProduct(product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.info_outline, color: ThemeColors.accent),
                                        tooltip: 'Info',
                                        onPressed: () => _showProductInfo(product),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
