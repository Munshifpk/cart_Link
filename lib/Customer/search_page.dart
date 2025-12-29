import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cart_link/theme_data.dart';
import 'package:cart_link/constant.dart';
import 'product_purchase_page.dart';
import 'category_products_page.dart';
import 'shop_products_page.dart';
import 'cart_page.dart';
import 'notification_offers.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;
  late PageController _pageController;
  late FocusNode _searchFocusNode;

  List<dynamic> _products = [];
  List<dynamic> _shops = [];
  List<dynamic> _categories = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, products, shops, categories
  int _currentPage = 0;
  static const int _itemsPerPage = 6;
  static const String _historyKey = 'searchHistory';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _searchFocusNode = FocusNode();
    _loadHistory();
    if ((widget.initialQuery ?? '').isNotEmpty) {
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _products = [];
        _shops = [];
        _categories = [];
        _currentPage = 0;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final encodedQuery = Uri.encodeQueryComponent(trimmed);

      // Fetch products
      final productsResponse = await http
          .get(backendUri('/api/products/search', queryParameters: {'q': encodedQuery}))
          .timeout(const Duration(seconds: 10));

      // Fetch shops
      final shopsResponse = await http
          .get(backendUri('/api/Shops/search', queryParameters: {'q': encodedQuery}))
          .timeout(const Duration(seconds: 10));

      // Fetch categories
      final categoriesResponse = await http
          .get(backendUri('/api/categories/search', queryParameters: {'q': encodedQuery}))
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

          _currentPage = 0;
          _isLoading = false;
        });

        _updateHistory(trimmed);
        
        // Reset page controller position
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
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

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _searchHistory = prefs.getStringList(_historyKey) ?? [];
    });
  }

  Future<void> _updateHistory(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final existing = _searchHistory.where(
      (q) => q.toLowerCase() != normalized.toLowerCase(),
    );
    final updated = <String>[normalized, ...existing].take(10).toList();

    if (!mounted) return;
    setState(() {
      _searchHistory = updated;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, updated);
  }

  void _handleHistoryTap(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    setState(() {});
    _performSearch(query);
  }

  List<String> _getFilteredHistory() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _searchHistory;
    
    // Filter and sort by relevance
    final matches = _searchHistory.where((item) {
      return item.toLowerCase().contains(query);
    }).toList();
    
    // Sort: exact matches first, then starts-with, then contains
    matches.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();
      
      if (aLower == query && bLower != query) return -1;
      if (aLower != query && bLower == query) return 1;
      
      if (aLower.startsWith(query) && !bLower.startsWith(query)) return -1;
      if (!aLower.startsWith(query) && bLower.startsWith(query)) return 1;
      
      return 0;
    });
    
    return matches;
  }

  Widget _buildProductCard(dynamic product) {
    final name = product['name'] ?? product['productName'] ?? 'Unknown';
    final productId = (product['_id'] ?? product['id'])?.toString();
    final priceVal = _parsePrice(product['price']);
    final mrpVal = _parsePrice(product['mrp']);
    final hasDiscount = mrpVal > 0 && priceVal > 0 && priceVal < mrpVal;
    final discountPct = hasDiscount
        ? (((mrpVal - priceVal) / mrpVal) * 100).round()
        : 0;
    final available = _isAvailable(product);
    final shopName = product['shopName'];
    final images = product['images'] as List?;
    final image = (images != null && images.isNotEmpty) 
        ? images[0] 
        : (product['image'] ?? product['productImage'] ?? '');

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
            // Product Image (75%)
            Expanded(
              flex: 3,
              child: AspectRatio(
                aspectRatio: 1.1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    color: Colors.grey[200],
                  ),
                  child: productId != null
                      ? Hero(
                          tag: 'product-$productId',
                          child: _buildProductImage(image),
                        )
                      : _buildProductImage(image),
                ),
              ),
            ),
            // Product Info (25%)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    if (shopName != null && shopName.toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        shopName.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '₹${priceVal.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: ThemeColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₹${mrpVal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (hasDiscount)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '-$discountPct%',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (!hasDiscount) const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: available
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        available ? 'In stock' : 'Out',
                        style: TextStyle(
                          color: available ? Colors.green : Colors.red,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(dynamic shop) {
    final name = shop['shopName'] ?? shop['name'] ?? 'Unknown';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shop Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ThemeColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store,
                  size: 22,
                  color: ThemeColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              // Shop Name
              Text(
                name.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  address.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    final name = category['name'] ?? category['categoryName'] ?? 'Unknown';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.category,
                  size: 22,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              // Category Name
              Text(
                name.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String image) {
    if (image.isEmpty) {
      return _buildErrorImage();
    }
    
    if (image.startsWith('data:')) {
      try {
        final base64String = image.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildErrorImage(),
        );
      } catch (e) {
        return _buildErrorImage();
      }
    } else if (image.startsWith('http')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildErrorImage(),
      );
    }
    
    return _buildErrorImage();
  }

  Widget _buildShopImage(String image) {
    if (image.isEmpty) {
      return _buildErrorImage();
    }
    
    if (image.startsWith('data:')) {
      try {
        final base64String = image.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildErrorImage(),
        );
      } catch (e) {
        return _buildErrorImage();
      }
    } else if (image.startsWith('http')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildErrorImage(),
      );
    }
    
    return _buildErrorImage();
  }

  Widget _buildCategoryImage(String image) {
    if (image.isEmpty) {
      return _buildErrorImage();
    }
    
    if (image.startsWith('data:')) {
      try {
        final base64String = image.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildErrorImage(),
        );
      } catch (e) {
        return _buildErrorImage();
      }
    } else if (image.startsWith('http')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
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
        elevation: 2,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search products, shops, categories...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _products = [];
                          _shops = [];
                          _categories = [];
                        });
                      },
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        _selectedFilter = value;
                        _currentPage = 0;
                      });
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'all',
                        child: Row(
                          children: [
                            Icon(
                              Icons.apps,
                              color: _selectedFilter == 'all'
                                  ? ThemeColors.primary
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'All',
                              style: TextStyle(
                                color: _selectedFilter == 'all'
                                    ? ThemeColors.primary
                                    : Colors.black87,
                                fontWeight: _selectedFilter == 'all'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'products',
                        child: Row(
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              color: _selectedFilter == 'products'
                                  ? ThemeColors.primary
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Products',
                              style: TextStyle(
                                color: _selectedFilter == 'products'
                                    ? ThemeColors.primary
                                    : Colors.black87,
                                fontWeight: _selectedFilter == 'products'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'shops',
                        child: Row(
                          children: [
                            Icon(
                              Icons.store,
                              color: _selectedFilter == 'shops'
                                  ? ThemeColors.primary
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Shops',
                              style: TextStyle(
                                color: _selectedFilter == 'shops'
                                    ? ThemeColors.primary
                                    : Colors.black87,
                                fontWeight: _selectedFilter == 'shops'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'categories',
                        child: Row(
                          children: [
                            Icon(
                              Icons.category,
                              color: _selectedFilter == 'categories'
                                  ? ThemeColors.primary
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Categories',
                              style: TextStyle(
                                color: _selectedFilter == 'categories'
                                    ? ThemeColors.primary
                                    : Colors.black87,
                                fontWeight: _selectedFilter == 'categories'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.tune, color: Colors.grey, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            ),
            onTap: () {},
            onChanged: (value) {
              // Rebuild to keep the clear icon visibility in sync with the field value
              setState(() {});
            },
            onSubmitted: (value) {
              _performSearch(value);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerCartPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OffersFollowedShopsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_searchHistory.isNotEmpty && _getFilteredHistory().isNotEmpty && (_products.isEmpty && _shops.isEmpty && _categories.isEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent searches',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: _getFilteredHistory()
                          .map(
                            (q) => ActionChip(
                              label: Text(q),
                              onPressed: () => _handleHistoryTap(q),
                              backgroundColor: Colors.grey[200],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
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
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  int totalPages = _getTotalPages();
                  int validPage = page.clamp(0, totalPages > 0 ? totalPages - 1 : 0);
                  setState(() => _currentPage = validPage);
                },
                itemCount: _getTotalPages(),
                itemBuilder: (context, pageIndex) {
                  return _buildPageContent(pageIndex);
                },
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
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = _columnsForWidth(constraints.maxWidth);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _getPaginatedProducts().length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(_getPaginatedProducts()[index]);
                  },
                );
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = _columnsForWidth(constraints.maxWidth);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _relatedItems().length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(_relatedItems()[index]);
                    },
                  );
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
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = _columnsForWidth(constraints.maxWidth);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _getPaginatedShops().length,
                  itemBuilder: (context, index) {
                    return _buildShopCard(_getPaginatedShops()[index]);
                  },
                );
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
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = _columnsForWidth(constraints.maxWidth);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _getPaginatedCategories().length,
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(_getPaginatedCategories()[index]);
                  },
                );
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
      selectedColor: ThemeColors.primary.withOpacity(0.3),
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

  // Responsive column calculation
  int _columnsForWidth(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  // Pagination helpers
  List<dynamic> _getPaginatedProducts() {
    if (_products.isEmpty) return [];
    int totalPages = _getTotalPages();
    if (totalPages == 0) return [];
    int validPage = _currentPage.clamp(0, max(0, totalPages - 1));
    final start = validPage * _itemsPerPage;
    if (start >= _products.length) return [];
    final end = (start + _itemsPerPage).clamp(0, _products.length);
    return _products.sublist(start, end);
  }

  List<dynamic> _getPaginatedShops() {
    if (_shops.isEmpty) return [];
    int totalPages = _getTotalPages();
    if (totalPages == 0) return [];
    int validPage = _currentPage.clamp(0, max(0, totalPages - 1));
    final start = validPage * _itemsPerPage;
    if (start >= _shops.length) return [];
    final end = (start + _itemsPerPage).clamp(0, _shops.length);
    return _shops.sublist(start, end);
  }

  List<dynamic> _getPaginatedCategories() {
    if (_categories.isEmpty) return [];
    int totalPages = _getTotalPages();
    if (totalPages == 0) return [];
    int validPage = _currentPage.clamp(0, max(0, totalPages - 1));
    final start = validPage * _itemsPerPage;
    if (start >= _categories.length) return [];
    final end = (start + _itemsPerPage).clamp(0, _categories.length);
    return _categories.sublist(start, end);
  }

  int _getTotalPages() {
    int maxLength = 0;
    if (_shouldShowProducts()) maxLength = max(maxLength, _products.length);
    if (_shouldShowShops()) maxLength = max(maxLength, _shops.length);
    if (_shouldShowCategories()) maxLength = max(maxLength, _categories.length);
    return ((maxLength + _itemsPerPage - 1) / _itemsPerPage).ceil();
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool _isAvailable(dynamic p) {
    try {
      if (p is Map<String, dynamic>) {
        if (p.containsKey('inStock')) return p['inStock'] == true;
        if (p.containsKey('stock')) {
          final s = p['stock'];
          if (s is num) return s > 0;
          if (s is String) return int.tryParse(s) != null && int.parse(s) > 0;
        }
      }
    } catch (_) {}
    return true;
  }

  void _nextPage() {
    int totalPages = _getTotalPages();
    int nextPage = _currentPage + 1;
    if (nextPage < totalPages && _pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    int previousPage = _currentPage - 1;
    if (previousPage >= 0 && _pageController.hasClients) {
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
