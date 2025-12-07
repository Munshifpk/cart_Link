import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:cart_link/theme_data.dart';
import 'product_purchase_page.dart';
import 'category_products_page.dart';
import 'shop_products_page.dart';

String get _backendBase {
  return 'http://localhost:5000';
}

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;
  late PageController _pageController;

  List<dynamic> _products = [];
  List<dynamic> _shops = [];
  List<dynamic> _categories = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, products, shops, categories
  int _currentPage = 0;
  static const int _itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    if ((widget.initialQuery ?? '').isNotEmpty) {
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _products = [];
        _shops = [];
        _categories = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final encodedQuery = Uri.encodeQueryComponent(query);

      // Fetch products
      final productsResponse = await http
          .get(Uri.parse('$_backendBase/api/products/search?q=$encodedQuery'))
          .timeout(const Duration(seconds: 10));

      // Fetch shops
      final shopsResponse = await http
          .get(Uri.parse('$_backendBase/api/Shops/search?q=$encodedQuery'))
          .timeout(const Duration(seconds: 10));

      // Fetch categories
      final categoriesResponse = await http
          .get(Uri.parse('$_backendBase/api/categories/search?q=$encodedQuery'))
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          if (productsResponse.statusCode == 200) {
            final data = jsonDecode(productsResponse.body);
            _products = data['data'] ?? data ?? [];
          }

          if (shopsResponse.statusCode == 200) {
            final data = jsonDecode(shopsResponse.body);
            _shops = data['data'] ?? data ?? [];
          }

          if (categoriesResponse.statusCode == 200) {
            final data = jsonDecode(categoriesResponse.body);
            _categories = data['data'] ?? data ?? [];
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProductCard(dynamic product) {
    final name = product['name'] ?? product['productName'] ?? 'Unknown';
    final price = product['price'] ?? 0;
    final image = product['image'] ?? product['productImage'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProductPurchasePage(offer: product as Map<String, dynamic>),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                color: Colors.grey[200],
              ),
              child: _buildProductImage(image),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${price.toString()}',
                    style: TextStyle(
                      color: ThemeColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(dynamic shop) {
    final name = shop['shopName'] ?? shop['name'] ?? 'Unknown';
    final image = shop['shopImage'] ?? shop['image'] ?? '';
    final address = shop['shopAddress'] ?? shop['address'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ShopProductsPage(shop: shop as Map<String, dynamic>),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                color: Colors.grey[200],
              ),
              child: _buildShopImage(image),
            ),
            // Shop Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    final name = category['name'] ?? category['categoryName'] ?? 'Unknown';
    final image = category['image'] ?? category['categoryImage'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProductsPage(category: name),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                color: Colors.grey[200],
              ),
              child: _buildCategoryImage(image),
            ),
            // Category Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                name.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String image) {
    if (image.startsWith('data:')) {
      try {
        final base64String = image.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return _buildErrorImage();
      }
    } else if (image.isNotEmpty) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorImage(),
      );
    }
    return _buildErrorImage();
  }

  Widget _buildShopImage(String image) {
    if (image.startsWith('data:')) {
      try {
        final base64String = image.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return _buildErrorImage();
      }
    } else if (image.isNotEmpty) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorImage(),
      );
    }
    return _buildErrorImage();
  }

  Widget _buildCategoryImage(String image) {
    if (image.startsWith('data:')) {
      try {
        final base64String = image.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return _buildErrorImage();
      }
    } else if (image.isNotEmpty) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorImage(),
      );
    }
    return _buildErrorImage();
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ThemeColors.primary,
        foregroundColor: ThemeColors.textColorWhite,
        title: const Text('Search'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products, shops, categories...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ThemeColors.primary, width: 2),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _products = [];
                            _shops = [];
                            _categories = [];
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) {
                _performSearch(value);
              },
            ),
          ),

          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Products', 'products'),
                const SizedBox(width: 8),
                _buildFilterChip('Shops', 'shops'),
                const SizedBox(width: 8),
                _buildFilterChip('Categories', 'categories'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Results with PageView for Swipe Navigation
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ThemeColors.primary,
                  ),
                ),
              ),
            )
          else if (_searchController.text.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Start searching',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_products.isEmpty && _shops.isEmpty && _categories.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.not_interested,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try searching with different keywords',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // PageView for Swipe Navigation
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                      itemCount: _getTotalPages(),
                      itemBuilder: (context, pageIndex) {
                        return _buildPageContent(pageIndex);
                      },
                    ),
                  ),

                  // Pagination Controls
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Page Indicators (Dots)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _getTotalPages(),
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 12 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? ThemeColors.primary
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Navigation Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _currentPage > 0
                                  ? _previousPage
                                  : null,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Previous'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ThemeColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                            ),
                            Text(
                              'Page ${_currentPage + 1} of ${_getTotalPages()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _currentPage < _getTotalPages() - 1
                                  ? _nextPage
                                  : null,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Next'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ThemeColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageContent(int pageIndex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Products Section
          if (_shouldShowProducts() && _products.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Products (${_products.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _getPaginatedProducts().length,
              itemBuilder: (context, index) {
                return _buildProductCard(_getPaginatedProducts()[index]);
              },
            ),
            const SizedBox(height: 24),

            // Related Items Section
            if (_relatedItems().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Related Items',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _relatedItems().length,
                itemBuilder: (context, index) {
                  return _buildProductCard(_relatedItems()[index]);
                },
              ),
              const SizedBox(height: 24),
            ],
          ],

          // Shops Section
          if (_shouldShowShops() && _shops.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shops (${_shops.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _getPaginatedShops().length,
              itemBuilder: (context, index) {
                return _buildShopCard(_getPaginatedShops()[index]);
              },
            ),
            const SizedBox(height: 24),
          ],

          // Categories Section
          if (_shouldShowCategories() && _categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories (${_categories.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _getPaginatedCategories().length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(_getPaginatedCategories()[index]);
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: ThemeColors.primary.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: isSelected ? ThemeColors.primary : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  bool _shouldShowProducts() {
    return _selectedFilter == 'all' || _selectedFilter == 'products';
  }

  bool _shouldShowShops() {
    return _selectedFilter == 'all' || _selectedFilter == 'shops';
  }

  bool _shouldShowCategories() {
    return _selectedFilter == 'all' || _selectedFilter == 'categories';
  }

  // Pagination helpers
  List<dynamic> _getPaginatedProducts() {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _products.length);
    return _products.sublist(start, end.clamp(0, _products.length));
  }

  List<dynamic> _getPaginatedShops() {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _shops.length);
    return _shops.sublist(start, end.clamp(0, _shops.length));
  }

  List<dynamic> _getPaginatedCategories() {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _categories.length);
    return _categories.sublist(start, end.clamp(0, _categories.length));
  }

  int _getTotalPages() {
    int maxLength = 0;
    if (_shouldShowProducts()) maxLength = max(maxLength, _products.length);
    if (_shouldShowShops()) maxLength = max(maxLength, _shops.length);
    if (_shouldShowCategories()) maxLength = max(maxLength, _categories.length);
    return ((maxLength + _itemsPerPage - 1) / _itemsPerPage).ceil();
  }

  void _nextPage() {
    int totalPages = _getTotalPages();
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Helper to get related items based on category or tag
  List<dynamic> _relatedItems() {
    if (_products.isEmpty) return [];
    final Set<String> categories = {};
    final Set<String> tags = {};
    for (var product in _products) {
      final cat = product['category'] ?? product['categoryName'];
      if (cat != null) categories.add(cat.toString().toLowerCase());
      final tagField = product['tags'] ?? product['tag'];
      if (tagField is String) {
        tags.add(tagField.toLowerCase());
      } else if (tagField is List) {
        for (var t in tagField) {
          tags.add(t.toString().toLowerCase());
        }
      }
    }
    // Find other products in the database (from _products) that share a category or tag but are not already in the current page
    return _products.where((product) {
      final cat = (product['category'] ?? product['categoryName'])
          ?.toString()
          .toLowerCase();
      final tagField = product['tags'] ?? product['tag'];
      bool tagMatch = false;
      if (tagField is String) {
        tagMatch = tags.contains(tagField.toLowerCase());
      } else if (tagField is List) {
        tagMatch = tagField.any(
          (t) => tags.contains(t.toString().toLowerCase()),
        );
      }
      return (cat != null && categories.contains(cat)) || tagMatch;
    }).toList();
  }
}
