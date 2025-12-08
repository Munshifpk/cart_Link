import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme_data.dart';
import 'package:cart_link/services/auth_state.dart';
import '../../services/product_service.dart';
import 'package:cart_link/constant.dart';

class ProductPurchasePage extends StatefulWidget {
  final Map<String, dynamic> offer;
  const ProductPurchasePage({super.key, required this.offer});

  @override
  State<ProductPurchasePage> createState() => _ProductPurchasePageState();
}

class _ProductPurchasePageState extends State<ProductPurchasePage> {
  late final ValueNotifier<int> _quantityNotifier;
  int _selectedImageIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _productData = {};
  String? _shopName;
  // similar products
  List<Map<String, dynamic>> _similarProducts = [];
  bool _loadingSimilar = false;
  // reviews & feedback
  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = false;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _hasPurchased = false;
  bool _checkingPurchase = false;

  @override
  void initState() {
    super.initState();
    _quantityNotifier = ValueNotifier<int>(1);
    _fetchProductAndShopDetails();
  }

  @override
  void dispose() {
    _quantityNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchProductAndShopDetails() async {
    try {
      final productId = widget.offer['_id'] ?? widget.offer['id'];
      final shopId =
          widget.offer['shopId'] ??
          widget.offer['ownerId'] ??
          widget.offer['shop'];

      if (productId == null || shopId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Invalid product or shop ID';
            _productData = widget.offer;
            _shopName = widget.offer['shopName'] ?? 'Unknown Shop';
          });
        }
        return;
      }

      // Fetch product details from /api/products?ownerId=$shopId and filter by productId
      final productResponse = await http
          .get(backendUri(kApiProducts, queryParameters: {'ownerId': shopId}))
          .timeout(const Duration(seconds: 8));

      if (productResponse.statusCode == 200) {
        final productsData =
            jsonDecode(productResponse.body)['data'] as List? ?? [];
        final productData = productsData.firstWhere(
          (p) =>
              p['_id']?.toString() == productId.toString() ||
              p['_id'] == productId,
          orElse: () => null,
        );

        if (productData == null) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Product not found';
              _productData = widget.offer;
            });
          }
          return;
        }

        // Fetch images for this product
        try {
          final imgs = await ProductService.getProductImages(
            productId.toString(),
          );
          if (imgs.isNotEmpty) {
            productData['images'] = imgs;
          }
        } catch (_) {
          // continue without images if fetch fails
        }

        // Validate and ensure all required product fields are present
        _validateProductData(productData);

        // Fetch shop details
        final shopResponse = await http
            .get(backendUri('$kApiShops/$shopId'))
            .timeout(const Duration(seconds: 8));

        String shopName = 'Unknown Shop';
        if (shopResponse.statusCode == 200) {
          final shopData =
              jsonDecode(shopResponse.body)['data'] ??
              jsonDecode(shopResponse.body);
          shopName = shopData['shopName'] ?? 'Unknown Shop';
        }

        // Merge shop name with product data
        productData['shopName'] = shopName;

        if (mounted) {
          setState(() {
            _productData = productData;
            _shopName = shopName;
            _isLoading = false;
          });
          // fetch similar products (by category) after product details
          try {
            final pId = productId?.toString();
            final category = productData['category']?.toString();
            final ownerId = shopId?.toString();
            if (ownerId != null) _fetchSimilarProducts(ownerId, category, pId);
            // fetch reviews for this product
            if (pId != null) {
              _fetchReviews(pId);
              _checkPurchaseStatus(pId);
            }
          } catch (_) {}
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load product details';
            _productData = widget.offer;
            _shopName = widget.offer['shopName'] ?? 'Unknown Shop';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading product: $e';
          _productData = widget.offer;
          _shopName = widget.offer['shopName'] ?? 'Unknown Shop';
        });
      }
    }
  }

  // Helper to determine availability from product document
  bool _isAvailable(Map<String, dynamic>? p) {
    if (p == null) return false;
    try {
      if (p.containsKey('inStock')) return p['inStock'] == true;
      if (p.containsKey('stock')) {
        final s = p['stock'];
        if (s is num) return s > 0;
        if (s is String) return int.tryParse(s) != null && int.tryParse(s)! > 0;
      }
    } catch (_) {}
    // default to true when field not provided (preserve existing behavior)
    return true;
  }

  Future<void> _fetchSimilarProducts(
    String ownerId,
    String? category,
    String? currentProductId,
  ) async {
    setState(() => _loadingSimilar = true);
    try {
      final uri = backendUri(
        kApiProducts,
        queryParameters: {'ownerId': ownerId},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> list = body is Map && body.containsKey('data')
            ? (body['data'] as List<dynamic>)
            : (body is List ? body : []);
        // Fetch images for each product
        final withImages = await Future.wait(
          list.map<Future<Map<String, dynamic>>>((p) async {
            final Map<String, dynamic> map = Map<String, dynamic>.from(
              p as Map,
            );
            try {
              final id = (map['_id'] ?? map['id'] ?? '').toString();
              if (id.isNotEmpty) {
                final imgs = await ProductService.getProductImages(id);
                if (imgs.isNotEmpty) map['images'] = imgs;
              }
            } catch (_) {}
            return map;
          }),
        );
        // filter by category (if provided), exclude current product and require availability
        final filtered = withImages
            .where((p) {
              try {
                // Exclude current product
                if (currentProductId != null &&
                    (p['_id']?.toString() == currentProductId ||
                        p['id']?.toString() == currentProductId))
                  return false;

                // Must be available to customers
                if (!_isAvailable(Map<String, dynamic>.from(p as Map)))
                  return false;

                if (category != null && category.isNotEmpty) {
                  return (p['category']?.toString() ?? '').toLowerCase() ==
                      category.toLowerCase();
                }
                // if no category provided, pick other products (active)
                return (p['isActive'] ?? true) == true;
              } catch (_) {
                return false;
              }
            })
            .take(10)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _similarProducts = filtered.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      // ignore errors silently
    } finally {
      if (mounted) setState(() => _loadingSimilar = false);
    }
  }

  Future<void> _fetchReviews(String productId) async {
    setState(() => _loadingReviews = true);
    try {
      // Try to fetch reviews from two common endpoints
      Uri uri = backendUri(
        '/api/reviews',
        queryParameters: {'productId': productId},
      );
      var res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        uri = backendUri('$kApiProducts/$productId/reviews');
        res = await http.get(uri).timeout(const Duration(seconds: 8));
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> list = body is Map && body.containsKey('data')
            ? (body['data'] as List<dynamic>)
            : (body is List ? body : []);
        final parsed = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) {
          setState(() {
            _reviews = parsed;
            _totalReviews = _reviews.length;
            if (_totalReviews > 0) {
              _averageRating =
                  _reviews
                      .map((r) => (r['rating'] ?? 0))
                      .fold<double>(
                        0.0,
                        (p, e) =>
                            p +
                            (e is num
                                ? e.toDouble()
                                : double.tryParse(e.toString()) ?? 0.0),
                      ) /
                  _totalReviews;
            } else {
              _averageRating = 0.0;
            }
          });
        }
      }
    } catch (_) {
      // ignore errors
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _checkPurchaseStatus(String productId) async {
    setState(() => _checkingPurchase = true);
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];
      if (customerId == null) {
        setState(() => _hasPurchased = false);
        return;
      }

      final uri = backendUri(
        '/api/orders',
        queryParameters: {
          'customerId': customerId.toString(),
          'productId': productId,
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> list = body is Map && body.containsKey('data')
            ? (body['data'] as List<dynamic>)
            : (body is List ? body : []);
        setState(() => _hasPurchased = (list.isNotEmpty));
      } else {
        setState(() => _hasPurchased = false);
      }
    } catch (_) {
      setState(() => _hasPurchased = false);
    } finally {
      if (mounted) setState(() => _checkingPurchase = false);
    }
  }

  /// Parse numeric value from database field safely
  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Validate and ensure product data has required pricing fields
  void _validateProductData(Map<String, dynamic> productData) {
    // Ensure price is valid
    if (!productData.containsKey('price') || productData['price'] == null) {
      productData['price'] = productData['mrp'] ?? 0;
    } else {
      productData['price'] = _parsePrice(productData['price']);
    }

    // Ensure MRP is valid
    if (!productData.containsKey('mrp') || productData['mrp'] == null) {
      productData['mrp'] = productData['price'] ?? 0;
    } else {
      productData['mrp'] = _parsePrice(productData['mrp']);
    }

    // Ensure offerPrice is present and valid
    if (!productData.containsKey('offerPrice') ||
        productData['offerPrice'] == null) {
      productData['offerPrice'] = productData['price'] ?? 0;
    } else {
      productData['offerPrice'] = _parsePrice(productData['offerPrice']);
    }

    // Calculate discount if not provided
    final mrp = _parsePrice(productData['mrp']);
    final price = _parsePrice(productData['price']);
    if (!productData.containsKey('discount') ||
        productData['discount'] == null) {
      if (mrp > 0 && price < mrp) {
        productData['discount'] = ((mrp - price) / mrp * 100).toStringAsFixed(
          0,
        );
      } else {
        productData['discount'] = 0;
      }
    }

    // Ensure description is present
    if (!productData.containsKey('description') ||
        productData['description'] == null) {
      final productName =
          productData['name'] ??
          productData['product'] ??
          productData['productName'] ??
          'Product';
      productData['description'] =
          'High-quality $productName with excellent quality and durability.';
    }

    // Ensure category exists
    if (!productData.containsKey('category') ||
        productData['category'] == null) {
      productData['category'] = 'General';
    }

    // Ensure images is a list
    if (!productData.containsKey('images') || productData['images'] is! List) {
      productData['images'] = [];
    }
  }

  Future<void> _submitReview(
    int rating,
    String message,
    String? imageUrl,
  ) async {
    try {
      final productId =
          _productData['_id'] ??
          _productData['id'] ??
          widget.offer['_id'] ??
          widget.offer['id'];
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];
      if (productId == null || customerId == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login required to submit review')),
          );
        return;
      }

      final uri = backendUri('/api/reviews');
      final Map<String, dynamic> payload = {
        'productId': productId,
        'customerId': customerId,
        'rating': rating,
        'message': message,
      };
      if (imageUrl != null && imageUrl.isNotEmpty)
        payload['imageUrl'] = imageUrl;
      final body = jsonEncode(payload);
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your feedback')),
          );
          final pid = productId.toString();
          await _fetchReviews(pid);
        }
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit review')),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<bool> _addToCartRequest(Map<String, dynamic> offer, int qty) async {
    try {
      final shopId = offer['shopId'] ?? offer['ownerId'] ?? offer['shop'];
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];

      // Check if customerId is available
      if (customerId == null || customerId.toString().isEmpty) {
        // ignore: avoid_print
        print('❌ Add to cart failed: customerId not found in AuthState');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to add items to cart'),
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }

      if (shopId == null || shopId.toString().isEmpty) {
        // ignore: avoid_print
        print('❌ Add to cart failed: shopId not found');
        return false;
      }

      // If the offer already contains `items` (array), prefer sending that
      // i.e. support sending multiple products for the same shop in one request.
      if (offer['items'] is List) {
        final items = (offer['items'] as List).map((it) {
          final pid = it['_id'] ?? it['id'] ?? it['productId'];
          final q = it['quantity'] ?? it['qty'] ?? 1;
          return {'productId': pid, 'quantity': q};
        }).toList();

        final body = jsonEncode({
          'items': items,
          'customerId': customerId,
          'shopId': shopId,
        });

        final uri = backendUri(kApiCart);
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 15));
        if (res.statusCode == 201 || res.statusCode == 200) return true;
        // ignore: avoid_print
        print('Add to cart failed: ${res.statusCode} ${res.body}');
        return false;
      }

      // Fallback: single product
      final productId = offer['_id'] ?? offer['id'] ?? offer['productId'];
      final body = jsonEncode({
        'productId': productId,
        'customerId': customerId,
        'shopId': shopId,
        'quantity': qty,
      });

      final uri = backendUri(kApiCart);
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 201 || res.statusCode == 200) return true;
      // debug log
      // ignore: avoid_print
      print('Add to cart failed: ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Add to cart error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Product...'),
          foregroundColor: ThemeColors.textColorWhite,
          backgroundColor: ThemeColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
          foregroundColor: ThemeColors.textColorWhite,
          backgroundColor: ThemeColors.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final offer = _productData.isNotEmpty ? _productData : widget.offer;
    // normalize incoming offer data (adds offerPrice, price, mrp, images etc.)
    try {
      _validateProductData(offer);
    } catch (_) {}

    // Compute normalized prices once for use throughout build
    final double offerPrice = _parsePrice(
      offer['offerPrice'] ?? offer['price'] ?? 0,
    );
    final double mrp = _parsePrice(offer['mrp'] ?? 0);
    final double discount = _parsePrice(offer['discount'] ?? 0);

    final String productTitle =
        (offer['name'] ??
                offer['product'] ??
                offer['productName'] ??
                _productData['name'] ??
                _productData['product'] ??
                _productData['title'])
            ?.toString() ??
        'Product';
    final String shopDisplayName =
        (_productData['shopName'] ??
                _shopName ??
                offer['shopName'] ??
                offer['shop'])
            ?.toString() ??
        'Unknown Shop';

    final images = (offer['images'] is List)
        ? (offer['images'] as List).cast<String>()
        : <String>[];
    final mainImage = images.isNotEmpty
        ? images[_selectedImageIndex.clamp(0, images.length - 1)]
        : null;

    // Determine availability for this offer/product
    final bool available = _isAvailable(offer);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          productTitle.isNotEmpty ? productTitle : 'Purchase Product',
        ),
        foregroundColor: ThemeColors.textColorWhite,
        backgroundColor: ThemeColors.primary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          Widget thumbnails(double height) => SizedBox(
            height: height,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    width: height,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedImageIndex == index
                            ? Colors.blue
                            : Colors.grey.shade300,
                        width: _selectedImageIndex == index ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: _buildImageWidget(images[index]),
                  ),
                );
              },
            ),
          );

          if (isWide) {
            // Side-by-side: image left, details right. Description full-width below.
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: big image + thumbnails
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _openImageViewer(
                                context,
                                images,
                                _selectedImageIndex,
                              ),
                              onHorizontalDragEnd: (details) {
                                if (images.isEmpty) return;
                                if (details.primaryVelocity == null) return;

                                if (details.primaryVelocity! > 0) {
                                  // Swipe right - previous image
                                  setState(() {
                                    _selectedImageIndex =
                                        (_selectedImageIndex -
                                            1 +
                                            images.length) %
                                        images.length;
                                  });
                                } else if (details.primaryVelocity! < 0) {
                                  // Swipe left - next image
                                  setState(() {
                                    _selectedImageIndex =
                                        (_selectedImageIndex + 1) %
                                        images.length;
                                  });
                                }
                              },
                              child: Container(
                                height: 460,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: mainImage != null
                                    ? _buildImageWidget(mainImage)
                                    : const Icon(
                                        Icons.image,
                                        size: 120,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (images.isNotEmpty) thumbnails(90),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right: product summary and actions
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // name, price, mrp, shop
                            Text(
                              productTitle,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              shopDisplayName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Availability badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: available
                                        ? Colors.green.withOpacity(0.12)
                                        : Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: available
                                          ? Colors.green.shade300
                                          : Colors.red.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    available ? 'Available' : 'Unavailable',
                                    style: TextStyle(
                                      color: available
                                          ? Colors.green.shade800
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (!available)
                                  Text(
                                    'This product is currently unavailable for purchase',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Price and MRP (MRP shown below price when available)
                            Text(
                              '₹${offerPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: available
                                      ? () {
                                          final newVal =
                                              (_quantityNotifier.value - 1) < 1
                                              ? 1
                                              : (_quantityNotifier.value - 1);
                                          _quantityNotifier.value = newVal;
                                        }
                                      : null,
                                  child: const Text('-'),
                                ),
                                const SizedBox(width: 16),
                                ValueListenableBuilder<int>(
                                  valueListenable: _quantityNotifier,
                                  builder: (context, qty, _) => Text(
                                    '$qty',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: available
                                      ? () {
                                          final newVal =
                                              (_quantityNotifier.value + 1) >
                                                  100
                                              ? 100
                                              : (_quantityNotifier.value + 1);
                                          _quantityNotifier.value = newVal;
                                        }
                                      : null,
                                  child: const Text('+'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Actions stacked vertically on wide screens
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: available
                                        ? () async {
                                            final qty = _quantityNotifier.value;
                                            final ok = await _addToCartRequest(
                                              offer,
                                              qty,
                                            );
                                            if (ok) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Added $qty item(s) to cart',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                              Future.delayed(
                                                const Duration(
                                                  milliseconds: 500,
                                                ),
                                                () {
                                                  if (context.mounted)
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/cart',
                                                    );
                                                },
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Failed to add to cart',
                                                  ),
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        : null,
                                    icon: const Icon(
                                      Icons.shopping_cart,
                                      size: 24,
                                    ),
                                    label: const Text(
                                      'Add to Cart',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: available
                                          ? ThemeColors.accent
                                          : Colors.grey.shade400,
                                      foregroundColor:
                                          ThemeColors.textColorWhite,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: available
                                        ? () {
                                            final qty = _quantityNotifier.value;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Proceeding to checkout for $qty item(s)...',
                                                ),
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    icon: const Icon(Icons.payment, size: 24),
                                    label: const Text(
                                      'Buy Now',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: available
                                          ? ThemeColors.greenButton
                                          : Colors.grey.shade400,
                                      foregroundColor:
                                          ThemeColors.textColorWhite,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description below spanning full width
                  const Text(
                    'Product Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offer['description'] ??
                        'High-quality product with excellent quality and durability.',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  // Similar products section
                  _buildSimilarProductsSection(),
                  const SizedBox(height: 24),
                  // Reviews & Feedback section
                  _buildReviewsSection(),
                ],
              ),
            );
          }

          // Small screens: stacked layout (image -> thumbnails -> details)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () =>
                      _openImageViewer(context, images, _selectedImageIndex),
                  onHorizontalDragEnd: (details) {
                    if (images.isEmpty) return;
                    if (details.primaryVelocity == null) return;

                    if (details.primaryVelocity! > 0) {
                      // Swipe right - previous image
                      setState(() {
                        _selectedImageIndex =
                            (_selectedImageIndex - 1 + images.length) %
                            images.length;
                      });
                    } else if (details.primaryVelocity! < 0) {
                      // Swipe left - next image
                      setState(() {
                        _selectedImageIndex =
                            (_selectedImageIndex + 1) % images.length;
                      });
                    }
                  },
                  child: Container(
                    height: 380,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: mainImage != null
                        ? _buildImageWidget(mainImage)
                        : const Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.grey,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                if (images.isNotEmpty) thumbnails(80),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildProductDetails(
                      offer,
                      productTitle,
                      shopDisplayName,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Similar products for small layout
                _buildSimilarProductsSection(),
                const SizedBox(height: 24),
                // Reviews for small layout
                _buildReviewsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimilarProductsSection() {
    if (_loadingSimilar) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_similarProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Similar Products',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _similarProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            padding: const EdgeInsets.only(right: 12),
            itemBuilder: (context, index) {
              final item = _similarProducts[index];
              final images = (item['images'] is List)
                  ? (item['images'] as List).cast<String>()
                  : <String>[];
              final thumb = images.isNotEmpty ? images[0] : '';

              return GestureDetector(
                onTap: () {
                  // Open the product page for the tapped similar product
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductPurchasePage(offer: item),
                      ),
                    );
                  }
                },
                child: SizedBox(
                  width: 140,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: thumb.isNotEmpty
                                  ? _buildImageWidget(thumb)
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 36,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (item['name'] ??
                                    item['product'] ??
                                    item['title'] ??
                                    '')
                                .toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${item['price'] ?? item['mrp'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildProductDetails(
    Map<String, dynamic> offer,
    String productTitle,
    String shopDisplayName,
  ) {
    // Compute availability
    final bool available = _isAvailable(offer);

    return [
      // Product name (use DB-fetched canonical title when available)
      Text(
        productTitle,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      // Shop name below product name (use DB-fetched shop name when available)
      Text(
        shopDisplayName,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 12),
      // Pricing (note: offerPrice, mrp, discount are pre-computed in build())
      Row(
        children: [
          Text(
            '₹${_parsePrice(offer['offerPrice'] ?? offer['price'] ?? 0).toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          if (_parsePrice(offer['discount'] ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '-${_parsePrice(offer['discount']).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      // Valid till
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offer valid till',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    offer['validTill'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      // Quantity selector
      const Text(
        'Quantity',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          ElevatedButton(
            onPressed: () {
              final newVal = (_quantityNotifier.value - 1) < 1
                  ? 1
                  : (_quantityNotifier.value - 1);
              _quantityNotifier.value = newVal;
            },
            child: const Text('-'),
          ),
          const SizedBox(width: 16),
          ValueListenableBuilder<int>(
            valueListenable: _quantityNotifier,
            builder: (context, qty, _) => Text(
              '$qty',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              final newVal = (_quantityNotifier.value + 1) > 100
                  ? 100
                  : (_quantityNotifier.value + 1);
              _quantityNotifier.value = newVal;
            },
            child: const Text('+'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      // Description
      const Text(
        'Product Description',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'High-quality ${(offer['product'] ?? 'product').toLowerCase()} with excellent quality and durability. Perfect for everyday use.',
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      const SizedBox(height: 24),
      // Add to cart and buy now buttons (side by side for small screens)
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: available
                    ? () async {
                        final qty = _quantityNotifier.value;
                        final ok = await _addToCartRequest(offer, qty);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $qty item(s) to cart'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (context.mounted) {
                              Navigator.pushNamed(context, '/cart');
                            }
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add to cart'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.shopping_cart, size: 20),
                style: ElevatedButton.styleFrom(
                  backgroundColor: available
                      ? ThemeColors.accent
                      : Colors.grey.shade400,
                  foregroundColor: ThemeColors.textColorWhite,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                ),
                label: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: available
                    ? () {
                        final qty = _quantityNotifier.value;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Proceeding to checkout for $qty item(s)...',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.payment, size: 20),
                label: const Text(
                  'Buy Now',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: available
                      ? ThemeColors.greenButton
                      : Colors.grey.shade400,
                  foregroundColor: ThemeColors.textColorWhite,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  void _openImageViewer(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    if (images.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) =>
          _ImageViewerDialog(images: images, initialIndex: initialIndex),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('data:')) {
      try {
        final parts = imageUrl.split(',');
        final b64 = parts.length > 1 ? parts.last : '';
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        );
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Reviews & Feedback',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 6),
            Text(
              _averageRating > 0 ? _averageRating.toStringAsFixed(1) : '0.0',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text('($_totalReviews reviews)'),
            const Spacer(),
            if (_checkingPurchase)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_hasPurchased)
              TextButton.icon(
                onPressed: () async {
                  // open review dialog (allow image URL attachment)
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (c) => _ReviewDialog(onSubmit: _submitReview),
                  );
                  if (result == true) {
                    // refresh handled by submit
                  }
                },
                icon: const Icon(Icons.rate_review, size: 18),
                label: const Text('Write a review'),
              )
            else
              const Text(
                'Only customers who purchased can review',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingReviews) const Center(child: CircularProgressIndicator()),
        if (!_loadingReviews && _reviews.isEmpty)
          const Text('No reviews yet. Be the first to review!'),
        if (_reviews.isNotEmpty)
          Column(
            children: _reviews.take(5).map((r) {
              final rating = (r['rating'] ?? 0);
              final msg = (r['message'] ?? r['text'] ?? '');
              final author =
                  (r['customerName'] ??
                          r['author'] ??
                          r['customerId'] ??
                          'Anonymous')
                      .toString();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(author.isNotEmpty ? author[0] : '?'),
                ),
                title: Row(
                  children: [
                    Text(
                      author,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· ${rating.toString()}',
                      style: const TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
                subtitle: Text(msg.toString()),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final Future<void> Function(int rating, String message, String? imageUrl)
  onSubmit;
  const _ReviewDialog({required this.onSubmit});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final TextEditingController _msg = TextEditingController();
  final TextEditingController _imageUrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _msg.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write a Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(5, (i) {
              final idx = i + 1;
              return IconButton(
                icon: Icon(
                  idx <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => _rating = idx),
              );
            }),
          ),
          TextField(
            controller: _msg,
            decoration: const InputDecoration(
              hintText: 'Write your feedback...',
            ),
            minLines: 2,
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _imageUrl,
            decoration: const InputDecoration(
              hintText: 'Optional: attach image URL',
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting
              ? null
              : () async {
                  setState(() => _submitting = true);
                  await widget.onSubmit(
                    _rating,
                    _msg.text.trim(),
                    _imageUrl.text.trim().isEmpty
                        ? null
                        : _imageUrl.text.trim(),
                  );
                  if (mounted) Navigator.pop(context, true);
                },
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class _ImageViewerDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageViewerDialog({required this.images, required this.initialIndex});

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;
  late Future<void> _autoSwipeFuture;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _startAutoSwipe();
  }

  void _startAutoSwipe() {
    _autoSwipeFuture = Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        final nextPage = (_currentIndex + 1) % widget.images.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      return mounted;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Image carousel with swipe navigation
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Center(
                child: _buildDialogImageWidget(widget.images[index]),
              );
            },
          ),

          // Top controls (close button and counter)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 12,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // Swipe indicator at bottom
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Auto-playing',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDialogImageWidget(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.image, size: 80, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('data:')) {
      try {
        final parts = imageUrl.split(',');
        final b64 = parts.length > 1 ? parts.last : '';
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
          ),
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
        );
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
      ),
    );
  }
}
