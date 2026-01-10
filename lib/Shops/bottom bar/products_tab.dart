import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/auth_state.dart'; // added
import '../../theme_data.dart';
import '../edit_product_page.dart';

class Product {
  final String id;
  final String name;
  final int stock;
  final bool inStock;
  final double price;
  final double? mrp;
  final String? description;
  final String? category;
  final String? sku;
  final bool isActive;
  final bool isFeatured;
  final List<String>? images;

  Product({
    required this.id,
    required this.name,
    required this.stock,
    this.inStock = true,
    required this.price,
    this.mrp,
    this.description,
    this.category,
    this.sku,
    this.isActive = true,
    this.isFeatured = false,
    this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unnamed Product',
      // If numeric stock isn't present, fall back to boolean inStock if provided
      stock: ((json['stock'] != null)
          ? (json['stock'] as num).toInt()
          : ((json['inStock'] == true) ? 1 : 0)),
      inStock:
          json['inStock'] ??
          ((json['stock'] != null) ? ((json['stock'] as num) > 0) : true),
      price: (json['price'] ?? 0.0).toDouble(),
      mrp: json['mrp'] != null ? (json['mrp'] as num).toDouble() : null,
      description: json['description'],
      category: json['category'],
      sku: json['sku'],
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }
}

class ProductsTab extends StatefulWidget {
  final Function(Function())? onRefreshCallback;

  const ProductsTab({super.key, this.onRefreshCallback});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  late Future<List<Product>> _productsFuture;
  List<Product> _products = [];
  bool _isRefreshing = false;

  Product _copyWithAvailability(Product p, bool inStock) {
    return Product(
      id: p.id,
      name: p.name,
      stock: p.stock,
      inStock: inStock,
      price: p.price,
      mrp: p.mrp,
      description: p.description,
      category: p.category,
      sku: p.sku,
      isActive: p.isActive,
      isFeatured: p.isFeatured,
      images: p.images,
    );
  }

  void _applyLocalAvailability(String productId, bool inStock) {
    setState(() {
      _products = _products
          .map((p) => p.id == productId ? _copyWithAvailability(p, inStock) : p)
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
    // Register the refresh callback with parent
    widget.onRefreshCallback?.call(_refreshProducts);
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
      final List<dynamic> productData = result['data'] ?? [];

      // Fetch images for each product on-demand (backend excludes images in list)
      final products = await Future.wait(
        productData.map<Future<Product>>((json) async {
          final Map<String, dynamic> map = Map<String, dynamic>.from(json);
          try {
            final id = (map['_id'] ?? map['id'] ?? '').toString();
            if (id.isNotEmpty) {
              final imgs = await ProductService.getProductImages(id);
              if (imgs.isNotEmpty) map['images'] = imgs;
            }
          } catch (_) {
            // ignore image fetch errors, continue without images
          }
          return Product.fromJson(map);
        }),
      );

      if (mounted) {
        setState(() {
          _products = products;
        });
      }

      return products;
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

  Future<void> _refreshProducts() async {
    setState(() {
      _isRefreshing = true;
      _productsFuture = _fetchProducts();
    });

    await _productsFuture;
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductPage(
          productId: product.id,
          productName: product.name,
          productPrice: product.price,
          productStock: product.stock,
        ),
      ),
    ).then((_) {
      if (mounted) _refreshProducts();
    });
  }

  void _deleteProduct(Product product) {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete ${product.name}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(
                  content: Text('Deleting product...'),
                  duration: Duration(seconds: 2),
                ),
              );

              final result = await ProductService.deleteProduct(product.id);
              if (!mounted) return;

              if (result['success'] == true) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} deleted successfully'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                _refreshProducts();
              } else {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'] ?? 'Failed to delete product',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _setProductAvailability(Product product, bool available) async {
    // Optimistically update the UI for snappier feedback
    _applyLocalAvailability(product.id, available);

    final res = await ProductService.updateProduct(product.id, {
      'inStock': available,
    });

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} is now ${available ? 'available' : 'unavailable'}',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      // Revert if backend update failed
      _applyLocalAvailability(product.id, !available);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to update availability'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmAvailabilityChange(
    Product product,
    bool available,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm availability change'),
        content: Text(
          "Mark ${product.name} as ${available ? 'Available' : 'Unavailable'}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _setProductAvailability(product, available);
    }
  }

  void _showProductInfo(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Name
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Status badges
              Row(
                children: [
                  if (product.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (product.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ThemeColors.accent),
                      ),
                      child: Text(
                        '⭐ Featured',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              const Divider(),

              // Price Information
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selling Price',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (product.mrp != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MRP',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${product.mrp!.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              product.inStock ? 'Yes' : 'No',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: product.inStock
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              tooltip: 'Toggle availability',
                              icon: Icon(
                                product.inStock
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: product.inStock
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              onPressed: () => _confirmAvailabilityChange(
                                product,
                                !product.inStock,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Category
              if (product.category != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.category, size: 18, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              product.category!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // SKU
              if (product.sku != null && product.sku!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.barcode_reader,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SKU',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              product.sku!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Description
              if (product.description != null &&
                  product.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editProduct(product);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteProduct(product);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;

    return Scaffold(
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isRefreshing) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final snapshotProducts = snapshot.data;
          if (_products.isEmpty &&
              (snapshotProducts == null || snapshotProducts.isEmpty)) {
            return const Center(child: Text('No products found.'));
          }

          // Prefer the locally cached list so toggle updates don't require a refetch.
          final products = _products.isNotEmpty
              ? _products
              : (snapshotProducts ?? []);

          // For large screens: side-by-side layout
          if (isLargeScreen) {
            return Row(
              children: [
                // Left side: Products table
                Expanded(
                  flex: 3,
                  child: _buildProductsTable(products, isMediumScreen),
                ),
                // Right side: Checkout summary
                Expanded(flex: 1, child: _buildCheckoutSummary(products)),
              ],
            );
          }

          // For medium and small screens: single column
          return Column(
            children: [
              Expanded(child: _buildProductsTable(products, isMediumScreen)),
              if (isMediumScreen) _buildCompactCheckoutSummary(products),
            ],
          );
        },
      ),
    );
  }

  // Build the products table with responsive columns
  Widget _buildProductsTable(List<Product> products, bool isMediumScreen) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: ThemeColors.primary,
                        secondary: ThemeColors.accent,
                      ),
                    ),
                    child: DataTable(
                      headingRowHeight: isMediumScreen ? 56 : 48,
                      headingRowColor: WidgetStateProperty.all(
                        ThemeColors.primary,
                      ),
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: isMediumScreen ? 14 : 12,
                      ),
                      dataTextStyle: TextStyle(
                        color: Colors.black87,
                        fontSize: isMediumScreen ? 13 : 11,
                      ),
                      dataRowMinHeight: isMediumScreen ? 52 : 45,
                      dataRowMaxHeight: isMediumScreen ? 52 : 45,
                      columnSpacing: isMediumScreen ? 24 : 12,
                      dividerThickness: 1,
                      columns: [
                        const DataColumn(label: Text('Name')),
                        if (isMediumScreen)
                          const DataColumn(label: Text('Category')),
                        const DataColumn(label: Text('Available')),
                        const DataColumn(label: Text('Price'), numeric: true),
                        if (isMediumScreen)
                          const DataColumn(label: Text('Status')),
                        const DataColumn(label: Text('Actions')),
                      ],
                      rows: products.map((product) {
                        return DataRow(
                          cells: [
                            // Name with description
                            DataCell(
                              SizedBox(
                                width: isMediumScreen ? 150 : 100,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isMediumScreen &&
                                        product.description != null &&
                                        product.description!.isNotEmpty)
                                      Text(
                                        product.description!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Category (only on medium+ screens)
                            if (isMediumScreen)
                              DataCell(
                                Text(
                                  product.category ?? 'N/A',
                                  style: TextStyle(
                                    color: product.category != null
                                        ? Colors.black87
                                        : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            // Available switch
                            DataCell(
                              Transform.scale(
                                scale: 0.9,
                                child: Switch(
                                  value: product.inStock,
                                  onChanged: (v) =>
                                      _confirmAvailabilityChange(product, v),
                                  activeColor: Colors.green,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                            // Price
                            DataCell(
                              Container(
                                alignment: Alignment.centerRight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '₹${product.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: ThemeColors.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isMediumScreen &&
                                        product.mrp != null &&
                                        product.mrp! > product.price)
                                      Text(
                                        '₹${product.mrp!.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Status (only on medium+ screens)
                            if (isMediumScreen)
                              DataCell(
                                Wrap(
                                  spacing: 2,
                                  children: [
                                    if (product.isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          'Active',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    if (product.isFeatured)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ThemeColors.accent.withOpacity(
                                            0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          '⭐',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: ThemeColors.accent,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            // Actions
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: ThemeColors.primary,
                                      size: 18,
                                    ),
                                    tooltip: 'Edit',
                                    onPressed: () => _editProduct(product),
                                    padding: EdgeInsets.all(
                                      isMediumScreen ? 8 : 4,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    tooltip: 'Delete',
                                    onPressed: () => _deleteProduct(product),
                                    padding: EdgeInsets.all(
                                      isMediumScreen ? 8 : 4,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.info_outline,
                                      color: ThemeColors.accent,
                                      size: 18,
                                    ),
                                    tooltip: 'Info',
                                    onPressed: () => _showProductInfo(product),
                                    padding: EdgeInsets.all(
                                      isMediumScreen ? 8 : 4,
                                    ),
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
  }

  // Build checkout summary for large screens (right sidebar)
  Widget _buildCheckoutSummary(List<Product> products) {
    int totalProducts = products.length;
    double totalValue = products.fold(
      0.0,
      (sum, p) => sum + (p.price * p.stock),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildSummaryCard(
              'Total Products',
              totalProducts.toString(),
              Icons.inventory_2,
              ThemeColors.primary,
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              'Total Stock Value',
              '₹${totalValue.toStringAsFixed(0)}',
              Icons.trending_up,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              'Avg Price',
              totalProducts > 0
                  ? '₹${(products.fold(0.0, (sum, p) => sum + p.price) / totalProducts).toStringAsFixed(0)}'
                  : '₹0',
              Icons.price_check,
              ThemeColors.accent,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Active Products',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              products.where((p) => p.isActive).length.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build compact checkout summary for medium screens (bottom)
  Widget _buildCompactCheckoutSummary(List<Product> products) {
    int totalProducts = products.length;
    double totalValue = products.fold(
      0.0,
      (sum, p) => sum + (p.price * p.stock),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'Total Products',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                totalProducts.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primary,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'Total Value',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                '₹${totalValue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.success,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'Active',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                products.where((p) => p.isActive).length.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to build summary cards
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
