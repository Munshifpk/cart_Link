import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme_data.dart';
import 'package:cart_link/services/auth_state.dart';
import '../../services/product_service.dart';
import 'package:cart_link/constant.dart';
import 'order/checkout_page.dart';

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
  bool _isInCart = false;
  bool _checkingCart = false;
  int _cartItemCount = 0;
  List<Map<String, dynamic>> _compareList = [];
  bool _isInCompare = false;
  bool _loadingCompare = false;

  @override
  void initState() {
    super.initState();
    _quantityNotifier = ValueNotifier<int>(1);
    _fetchProductAndShopDetails();
    _fetchCartCount();
    _fetchCompareList();
  }

  @override
  void dispose() {
    _quantityNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchProductAndShopDetails() async {
    try {
      final productId =
          widget.offer['_id'] ??
          widget.offer['id'] ??
          widget.offer['productId'];
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

        // Always hydrate shop name from backend (ignore incoming offer value)
        final shopName = await _fetchShopNameFromBackend(shopId.toString());

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
              _checkCartStatus(pId, shopId?.toString());
              _checkCompareStatus(pId, shopId?.toString());
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

  Future<void> _checkCartStatus(String productId, String? shopId) async {
    setState(() => _checkingCart = true);
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];
      if (customerId == null || shopId == null) {
        setState(() => _isInCart = false);
        return;
      }

      final uri = backendUri(
        kApiCart,
        queryParameters: {
          'customerId': customerId.toString(),
          'shopId': shopId,
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> items = body is Map && body.containsKey('items')
            ? (body['items'] as List<dynamic>)
            : (body is List ? body : []);

        // Check if this product is in the cart
        final inCart = items.any((item) {
          final itemProductId = item['productId'] ?? item['_id'] ?? item['id'];
          return itemProductId.toString() == productId.toString();
        });
        setState(() => _isInCart = inCart);
      } else {
        setState(() => _isInCart = false);
      }
    } catch (_) {
      setState(() => _isInCart = false);
    } finally {
      if (mounted) setState(() => _checkingCart = false);
    }
  }

  Future<void> _fetchCartCount() async {
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];
      if (customerId == null) {
        setState(() => _cartItemCount = 0);
        return;
      }

      final uri = backendUri(
        kApiCart,
        queryParameters: {'customerId': customerId.toString()},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> items = body is Map && body.containsKey('items')
            ? (body['items'] as List<dynamic>)
            : (body is List ? body : []);

        int totalCount = 0;
        for (final item in items) {
          final qty = item['quantity'] ?? item['qty'] ?? 1;
          totalCount += (qty is num ? qty.toInt() : 1);
        }
        setState(() => _cartItemCount = totalCount);
      } else {
        setState(() => _cartItemCount = 0);
      }
    } catch (_) {
      setState(() => _cartItemCount = 0);
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
        if (res.statusCode == 201 || res.statusCode == 200) {
          await _fetchCartCount();
          // Refresh cart status for single item
          final productId = offer['_id'] ?? offer['id'] ?? offer['productId'];
          final shopId = offer['shopId'] ?? offer['ownerId'] ?? offer['shop'];
          if (productId != null && shopId != null) {
            await _checkCartStatus(productId.toString(), shopId.toString());
          }
          return true;
        }
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

      if (res.statusCode == 201 || res.statusCode == 200) {
        await _fetchCartCount();
        // Refresh cart status for this product
        final productId = offer['_id'] ?? offer['id'] ?? offer['productId'];
        final shopId = offer['shopId'] ?? offer['ownerId'] ?? offer['shop'];
        if (productId != null && shopId != null) {
          await _checkCartStatus(productId.toString(), shopId.toString());
          print('✅ Cart status checked: _isInCart=$_isInCart');
        }
        return true;
      }
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

  Future<void> _createOrderAndNavigate(int qty) async {
    // Build a single-shop checkout payload and navigate to CheckoutPage
    final offer = _productData.isNotEmpty ? _productData : widget.offer;
    final shopId = (offer['shopId'] ?? offer['ownerId'] ?? offer['shop'])
        ?.toString();
    final productId = (offer['_id'] ?? offer['id'] ?? offer['productId'])
        ?.toString();
    final shopName = (offer['shopName'] ?? _shopName ?? '').toString();

    if (shopId == null || productId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid product or shop data')),
        );
      }
      return;
    }

    final price = _parsePrice(offer['offerPrice'] ?? offer['price'] ?? 0);
    final mrp = _parsePrice(offer['mrp'] ?? price);
    final productName =
        (offer['name'] ?? offer['product'] ?? offer['title'] ?? '')?.toString();

    final items = [
      {
        'productId': productId,
        'productName': productName,
        'quantity': qty,
        'price': price,
        'mrp': mrp,
        'total': price * qty,
      },
    ];

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redirecting to checkout...')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutPage(
            shopId: shopId,
            shopName: shopName.isNotEmpty ? shopName : 'Shop',
            items: items,
          ),
        ),
      );
    }
  }

  /// Fetch the current compare list for the customer
  Future<void> _fetchCompareList() async {
    setState(() => _loadingCompare = true);
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];
      if (customerId == null) {
        setState(() {
          _compareList = [];
          _loadingCompare = false;
        });
        return;
      }

      final uri = backendUri(
        kApiCompare,
        queryParameters: {'customerId': customerId.toString()},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> items = body is Map && body.containsKey('items')
            ? (body['items'] as List<dynamic>)
            : (body is Map && body.containsKey('compareList')
                  ? (body['compareList'] as List<dynamic>)
                  : []);

        // Ensure shop names are hydrated from the database when missing
        final mappedItems = items
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        final enriched = await _populateShopNames(mappedItems);

        setState(() {
          _compareList = enriched;
        });
      } else {
        setState(() => _compareList = []);
      }
    } catch (_) {
      setState(() => _compareList = []);
    } finally {
      if (mounted) setState(() => _loadingCompare = false);
    }
  }

  /// Fetch shop names for compare list items that don't already have one
  Future<List<Map<String, dynamic>>> _populateShopNames(
    List<Map<String, dynamic>> items,
  ) async {
    final futures = items.map((item) async {
      final hasName =
          item['shopName'] != null &&
          item['shopName'].toString().trim().isNotEmpty;
      final shopId = item['shopId'] ?? item['ownerId'] ?? item['shop'];

      if (hasName || shopId == null) return item;

      try {
        item['shopName'] = await _fetchShopNameFromBackend(shopId.toString());
      } catch (_) {
        // ignore failures; keep existing data
      }

      return item;
    }).toList();

    return Future.wait(futures);
  }

  /// Fetch shop name from backend shop collection by shopId
  Future<String> _fetchShopNameFromBackend(String shopId) async {
    try {
      final uri = backendUri('$kApiShops/$shopId');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded is Map && decoded.containsKey('data')
            ? decoded['data']
            : decoded;
        if (data is Map && data['shopName'] != null) {
          return data['shopName'].toString();
        }
      }
    } catch (_) {
      // ignore errors and fall through to default
    }
    return 'Unknown Shop';
  }

  /// Check if current product is in compare list
  Future<void> _checkCompareStatus(String productId, String? shopId) async {
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];
      if (customerId == null || shopId == null) {
        setState(() => _isInCompare = false);
        return;
      }

      // Check if product exists in compare list
      final inCompare = _compareList.any((item) {
        final itemProductId = item['productId'] ?? item['_id'] ?? item['id'];
        final itemShopId = item['shopId'] ?? item['ownerId'];
        return itemProductId.toString() == productId.toString() &&
            itemShopId.toString() == shopId.toString();
      });
      setState(() => _isInCompare = inCompare);
    } catch (_) {
      setState(() => _isInCompare = false);
    }
  }

  /// Add product to compare list
  Future<bool> _addToCompare(Map<String, dynamic> offer) async {
    try {
      final shopId = offer['shopId'] ?? offer['ownerId'] ?? offer['shop'];
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];

      if (customerId == null || customerId.toString().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to use compare feature'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return false;
      }

      if (shopId == null) return false;

      final productId = offer['_id'] ?? offer['id'] ?? offer['productId'];

      // Check if already at max (3 products)
      if (_compareList.length >= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 3 products can be compared at once'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return false;
      }

      final body = jsonEncode({
        'productId': productId,
        'customerId': customerId,
        'shopId': shopId,
      });

      final uri = backendUri(kApiCompare);
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 201 || res.statusCode == 200) {
        await _fetchCompareList();
        await _checkCompareStatus(productId.toString(), shopId.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to compare'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Add to compare error: $e');
      return false;
    }
  }

  /// Remove product from compare list
  Future<bool> _removeFromCompare(String productId, String shopId) async {
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];

      if (customerId == null) return false;

      final uri = backendUri(
        '$kApiCompare/$productId',
        queryParameters: {
          'customerId': customerId.toString(),
          'shopId': shopId,
        },
      );
      final res = await http.delete(uri).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 204) {
        await _fetchCompareList();
        await _checkCompareStatus(productId, shopId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from compare'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Remove from compare error: $e');
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
    // `mrp` and `discount` are accessed via helpers in other places; avoid unused local vars

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
            .toString();

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
        foregroundColor: ThemeColors.white,
        backgroundColor: ThemeColors.primary,
        actions: [
          // Compare Icon
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.balance),
                onPressed: () {
                  if (_compareList.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No products to compare'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  _showComparisonModal(context);
                },
                tooltip: 'Compare Products',
              ),
              if (_compareList.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: ThemeColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _compareList.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  if (context.mounted) {
                    Navigator.pushNamed(context, '/cart');
                  }
                },
                tooltip: 'Go to Cart',
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: ThemeColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
                            ? ThemeColors.primary
                            : ThemeColors.divider,
                        width: _selectedImageIndex == index ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: ThemeColors.surface,
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
                                  color: ThemeColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: mainImage != null
                                    ? _buildImageWidget(mainImage)
                                    : const Icon(
                                        Icons.image,
                                        size: 120,
                                        color: ThemeColors.textSecondary,
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
                                color: ThemeColors.primary,
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
                                        ? ThemeColors.success.withOpacity(0.12)
                                        : ThemeColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: available
                                          ? ThemeColors.success.withOpacity(0.3)
                                          : ThemeColors.error.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    available ? 'Available' : 'Unavailable',
                                    style: TextStyle(
                                      color: available
                                          ? ThemeColors.success
                                          : ThemeColors.error,
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
                                      color: ThemeColors.error,
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
                            // Add to Cart and Buy Now side by side on wide screens
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: available
                                          ? () async {
                                              if (_isInCart) {
                                                if (context.mounted) {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/cart',
                                                  );
                                                }
                                              } else {
                                                final qty =
                                                    _quantityNotifier.value;
                                                final ok =
                                                    await _addToCartRequest(
                                                      offer,
                                                      qty,
                                                    );
                                                if (ok && context.mounted) {
                                                  // Explicitly set button state to show "Go to Cart"
                                                  setState(
                                                    () => _isInCart = true,
                                                  );
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
                                                } else if (context.mounted) {
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
                                            }
                                          : null,
                                      icon: Icon(
                                        _isInCart
                                            ? Icons.check_circle
                                            : Icons.shopping_cart,
                                        size: 24,
                                      ),
                                      label: Text(
                                        _isInCart
                                            ? 'Go to Cart'
                                            : 'Add to Cart',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: available
                                            ? ThemeColors.primary
                                            : ThemeColors.divider,
                                        foregroundColor: ThemeColors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: available
                                          ? () async {
                                              final qty =
                                                  _quantityNotifier.value;
                                              await _createOrderAndNavigate(
                                                qty,
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
                                            ? ThemeColors.success
                                            : ThemeColors.divider,
                                        foregroundColor: ThemeColors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Add to Compare button (top of Product Details - wide screens)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: available
                                    ? () async {
                                        if (_isInCompare) {
                                          final productId =
                                              offer['_id'] ??
                                              offer['id'] ??
                                              offer['productId'];
                                          final shopId =
                                              offer['shopId'] ??
                                              offer['ownerId'] ??
                                              offer['shop'];
                                          if (productId != null &&
                                              shopId != null) {
                                            await _removeFromCompare(
                                              productId.toString(),
                                              shopId.toString(),
                                            );
                                          }
                                        } else {
                                          await _addToCompare(offer);
                                        }
                                      }
                                    : null,
                                icon: Icon(
                                  _isInCompare ? Icons.check : Icons.balance,
                                  size: 20,
                                ),
                                label: Text(
                                  _isInCompare
                                      ? 'Remove from Compare'
                                      : 'Add to Compare',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: available
                                      ? (_isInCompare
                                            ? Colors.orange
                                            : ThemeColors.primary)
                                      : Colors.grey.shade400,
                                  foregroundColor: ThemeColors.textColorWhite,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Product Details section (wide screens)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Product Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._buildProductDetailsFromDatabase(offer),
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
                  // Reviews & Feedback section
                  _buildReviewsSection(),
                  const SizedBox(height: 24),
                  _buildSimilarProductsSection(),
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
                      color: ThemeColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: mainImage != null
                        ? _buildImageWidget(mainImage)
                        : const Icon(
                            Icons.image,
                            size: 100,
                            color: ThemeColors.textSecondary,
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
                const SizedBox(height: 24),
                // Reviews for small layout
                _buildReviewsSection(),
                const SizedBox(height: 24),
                _buildSimilarProductsSection(),
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

    if (_similarProducts.isEmpty) return const SizedBox.shrink();

    final displayList = _similarProducts.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Similar Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_similarProducts.isNotEmpty)
              TextButton(
                onPressed: () {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            _AllSimilarProductsPage(items: _similarProducts),
                      ),
                    );
                  }
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            padding: const EdgeInsets.only(right: 12),
            itemBuilder: (context, index) {
              final item = displayList[index];
              final images = (item['images'] is List)
                  ? (item['images'] as List).cast<String>()
                  : <String>[];
              final thumb = images.isNotEmpty ? images[0] : '';

              return GestureDetector(
                onTap: () {
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
                                      color: ThemeColors.surface,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 36,
                                          color: ThemeColors.textSecondary,
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
                              color: ThemeColors.success,
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

  // Full-page listing for "View All"
  // (Moved to top-level to avoid nested-class syntax issues)

  List<Widget> _buildProductDetails(
    Map<String, dynamic> offer,
    String productTitle,
    String shopDisplayName,
  ) {
    // Compute availability
    final bool available = _isAvailable(offer);
    final offerPrice = _parsePrice(offer['offerPrice'] ?? offer['price'] ?? 0);
    final mrp = _parsePrice(offer['mrp'] ?? offerPrice);
    final discount = _parsePrice(offer['discount'] ?? 0);

    return [
      // Product name (use DB-fetched canonical title when available)
      Text(
        productTitle,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 6),
      // Shop name below product name (use DB-fetched shop name when available)
      Row(
        children: [
          const Icon(Icons.store, size: 16, color: ThemeColors.primary),
          const SizedBox(width: 6),
          Text(
            shopDisplayName,
            style: const TextStyle(
              fontSize: 14,
              color: ThemeColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      // Divider
      Container(height: 1, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      // Pricing Section
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ThemeColors.success.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: ThemeColors.success.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹${offerPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: ThemeColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                if (mrp > offerPrice)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${mrp.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                if (discount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-${discount.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: ThemeColors.textColorWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      // Stock availability badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: available ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: available ? Colors.green.shade300 : Colors.red.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              available ? Icons.check_circle : Icons.cancel,
              color: available ? ThemeColors.success : ThemeColors.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (!available) {
                    return const Text(
                      'Out of Stock',
                      style: TextStyle(
                        color: ThemeColors.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
                  final stock = offer['stock'];
                  final stockText = (stock != null && stock is num && stock > 0)
                      ? 'In Stock: ${stock.toInt()} available'
                      : 'In Stock';
                  return Text(
                    stockText,
                    style: const TextStyle(
                      color: ThemeColors.success,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      // Action buttons
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: available
                    ? () async {
                        if (_isInCart) {
                          if (context.mounted) {
                            Navigator.pushNamed(context, '/cart');
                          }
                        } else {
                          final qty = _quantityNotifier.value;
                          final ok = await _addToCartRequest(offer, qty);

                          if (ok && context.mounted) {
                            setState(() => _isInCart = true);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added $qty item(s) to cart'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to add to cart'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      }
                    : null,
                icon: Icon(
                  _isInCart ? Icons.check_circle : Icons.shopping_cart,
                  size: 22,
                ),
                label: Text(
                  _isInCart ? 'Go to Cart' : 'Add to Cart',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: available
                      ? ThemeColors.primary
                      : Colors.grey.shade400,
                  foregroundColor: ThemeColors.textColorWhite,
                  elevation: 3,
                  shadowColor: ThemeColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: available
                    ? () async {
                        final qty = _quantityNotifier.value;
                        await _createOrderAndNavigate(qty);
                      }
                    : null,
                icon: const Icon(Icons.flash_on, size: 22),
                label: const Text(
                  'Buy Now',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: available
                      ? ThemeColors.success
                      : Colors.grey.shade400,
                  foregroundColor: ThemeColors.textColorWhite,
                  elevation: 3,
                  shadowColor: ThemeColors.success.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Compare button
      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: available
              ? () async {
                  if (_isInCompare) {
                    final productId =
                        offer['_id'] ?? offer['id'] ?? offer['productId'];
                    final shopId =
                        offer['shopId'] ?? offer['ownerId'] ?? offer['shop'];
                    if (productId != null && shopId != null) {
                      await _removeFromCompare(
                        productId.toString(),
                        shopId.toString(),
                      );
                    }
                  } else {
                    await _addToCompare(offer);
                  }
                }
              : null,
          icon: Icon(
            _isInCompare ? Icons.check : Icons.balance,
            size: 20,
            color: _isInCompare ? Colors.orange : ThemeColors.primary,
          ),
          label: Text(
            _isInCompare ? 'Remove from Compare' : 'Add to Compare',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isInCompare ? Colors.orange : ThemeColors.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _isInCompare ? Colors.orange : ThemeColors.primary,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      // Divider
      Container(height: 1, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      // Quantity selector card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Quantity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () {
                            final newVal = (_quantityNotifier.value - 1) < 1
                                ? 1
                                : (_quantityNotifier.value - 1);
                            _quantityNotifier.value = newVal;
                          },
                          icon: const Icon(Icons.remove, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade400,
                      ),
                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: ValueListenableBuilder<int>(
                          valueListenable: _quantityNotifier,
                          builder: (context, qty, _) => Text(
                            '$qty',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () {
                            final stock = offer['stock'];
                            final maxQty =
                                (stock != null && stock is num && stock > 0)
                                ? stock.toInt()
                                : 100;
                            final newVal =
                                (_quantityNotifier.value + 1) > maxQty
                                ? maxQty
                                : (_quantityNotifier.value + 1);
                            _quantityNotifier.value = newVal;
                          },
                          icon: const Icon(Icons.add, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      // Product Details - Table Format
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ThemeColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildProductDetailsTable(offer),
          ],
        ),
      ),
      const SizedBox(height: 24),
      // Description section
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ThemeColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Text(
                offer['description'] ??
                    'High-quality ${(offer['product'] ?? 'product').toLowerCase()} with excellent quality and durability. Perfect for everyday use.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Build product details in professional table format
  List<Widget> _buildProductDetailsTable(Map<String, dynamic> offer) {
    // Fields to exclude from display
    final excludedFields = {
      '_id',
      'id',
      '__v',
      'createdAt',
      'updatedAt',
      'deletedAt',
      'isDeleted',
      'isActive',
      'name',
      'product',
      'productName',
      'title',
      'price',
      'offerPrice',
      'mrp',
      'discount',
      'description',
      'stock',
      'inStock',
      'category',
      'images',
      'shopId',
      'ownerId',
      'shop',
      'shopName',
    };

    final details = <Map<String, String>>[];
    final sortedKeys = offer.keys.toList()..sort();

    for (final key in sortedKeys) {
      if (excludedFields.contains(key)) continue;
      final value = offer[key];
      if (value == null) continue;
      if (value is String && value.toString().trim().isEmpty) continue;
      if (value is List && value.isEmpty) continue;
      if (value is Map && value.isEmpty) continue;

      details.add({
        'key': _formatFieldName(key),
        'value': _formatFieldValue(value),
      });
    }

    if (details.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No additional details available',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
        ),
      ];
    }

    // Build table rows
    final widgets = <Widget>[];
    for (int i = 0; i < details.length; i++) {
      final detail = details[i];
      final isOdd = i.isOdd;
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isOdd ? Colors.grey.shade50 : Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  detail['key']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  detail['value']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  /// Build a list of product detail widgets from all available database fields (kept for compatibility)
  List<Widget> _buildProductDetailsFromDatabase(Map<String, dynamic> offer) {
    return _buildProductDetailsTable(offer);
  }

  /// Convert camelCase field name to Title Case (e.g., "productColor" -> "Product Color")
  String _formatFieldName(String fieldName) {
    // Insert space before uppercase letters
    final withSpaces = fieldName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    // Capitalize first letter and trim
    final trimmed = withSpaces.trim();
    if (trimmed.isEmpty) return fieldName;
    return trimmed[0].toUpperCase() +
        (trimmed.length > 1 ? trimmed.substring(1) : '');
  }

  /// Format field value for display
  String _formatFieldValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    } else if (value is Map) {
      return value.toString();
    } else if (value is bool) {
      return value ? 'Yes' : 'No';
    } else if (value is num) {
      // Format numbers with decimal places if needed
      if (value is double && value.toStringAsFixed(0) != value.toString()) {
        return value.toStringAsFixed(2);
      }
      return value.toString();
    }
    return value.toString();
  }

  /// Show comparison modal with all products in compare list
  void _showComparisonModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ComparisonModalWidget(
        parentContext: context,
        compareList: _compareList,
        onRemove: (productId, shopId) async {
          await _removeFromCompare(productId, shopId);
          if (context.mounted) {
            // Refresh the modal with updated list
            Navigator.pop(context);
            _showComparisonModal(context);
          }
        },
      ),
    );
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

class _AllSimilarProductsPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _AllSimilarProductsPage({required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Similar Products'),
        backgroundColor: ThemeColors.primary,
        foregroundColor: ThemeColors.textColorWhite,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final images = (item['images'] is List)
                ? (item['images'] as List).cast<String>()
                : <String>[];
            final thumb = images.isNotEmpty ? images[0] : '';

            return GestureDetector(
              onTap: () {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductPurchasePage(offer: item),
                    ),
                  );
                }
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: thumb.isNotEmpty
                                  ? Image.network(thumb, fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${item['price'] ?? item['mrp'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stock Out Banner
                    if (item['inStock'] == false)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: -0.3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ThemeColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'STOCK OUT',
                                  style: TextStyle(
                                    color: ThemeColors.textColorWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _startAutoSwipe();
  }

  void _startAutoSwipe() {
    Future.doWhile(() async {
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

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
      ),
    );
  }
}

/// Price Comparison Modal Widget
class ComparisonModalWidget extends StatelessWidget {
  final List<Map<String, dynamic>> compareList;
  final Future<void> Function(String productId, String shopId) onRemove;
  final BuildContext parentContext;

  const ComparisonModalWidget({
    required this.parentContext,
    required this.compareList,
    required this.onRemove,
  });

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Compare Products',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Comparison table
              if (compareList.isEmpty)
                const Text('No products to compare yet')
              else
                Builder(
                  builder: (context) {
                    DataRow buildRow(
                      String label,
                      Widget Function(Map<String, dynamic> item) cellBuilder,
                    ) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          ...compareList.map(
                            (item) => DataCell(
                              SizedBox(width: 170, child: cellBuilder(item)),
                            ),
                          ),
                        ],
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        horizontalMargin: 8,
                        columns: [
                          const DataColumn(
                            label: Text(
                              'Details',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...compareList.map((item) {
                            final productName =
                                (item['name'] ??
                                        item['product'] ??
                                        item['productName'] ??
                                        'Product')
                                    .toString();
                            return DataColumn(
                              label: SizedBox(
                                width: 170,
                                child: Text(
                                  productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                        rows: [
                          buildRow(
                            'Shop',
                            (item) => Text(
                              (item['shopName'] ?? item['shop'] ?? 'Shop')
                                  .toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          buildRow('Price', (item) {
                            final price = _parsePrice(
                              item['offerPrice'] ?? item['price'] ?? 0,
                            );
                            return Text(
                              '₹${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.success,
                              ),
                            );
                          }),
                          buildRow('MRP', (item) {
                            final mrp = _parsePrice(item['mrp'] ?? 0);
                            return Text(
                              '₹${mrp.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            );
                          }),
                          buildRow('Discount', (item) {
                            final price = _parsePrice(
                              item['offerPrice'] ?? item['price'] ?? 0,
                            );
                            final mrp = _parsePrice(item['mrp'] ?? price);
                            final discount = mrp > 0
                                ? ((mrp - price) / mrp * 100)
                                : 0;

                            return Text(
                              discount > 0
                                  ? '-${discount.toStringAsFixed(0)}%'
                                  : 'No',
                              style: TextStyle(
                                fontSize: 12,
                                color: discount > 0
                                    ? ThemeColors.success
                                    : Colors.grey,
                              ),
                            );
                          }),
                          buildRow('Stock', (item) {
                            final stock = item['stock'] ?? 0;
                            final inStock = item['inStock'] ?? (stock > 0);
                            return Text(
                              inStock == true ? 'In Stock' : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 12,
                                color: inStock == true
                                    ? ThemeColors.success
                                    : Colors.red,
                              ),
                            );
                          }),
                          buildRow('View Product', (item) {
                            final productId =
                                (item['productId'] ?? item['_id'] ?? item['id'])
                                    ?.toString();
                            final shopId =
                                (item['shopId'] ??
                                        item['ownerId'] ??
                                        item['shop'])
                                    ?.toString();

                            // Prepare minimal offer so ProductPurchasePage can refetch fully
                            final offerForNavigation = {
                              ...item,
                              '_id': productId,
                              'productId': productId,
                              'shopId': shopId,
                              'shopName': item['shopName'],
                            }..removeWhere((key, value) => value == null);

                            return ElevatedButton.icon(
                              onPressed: (productId == null || shopId == null)
                                  ? null
                                  : () {
                                      Navigator.of(parentContext).pop();
                                      Future.microtask(() {
                                        Navigator.of(parentContext).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProductPurchasePage(
                                              offer: offerForNavigation,
                                            ),
                                          ),
                                        );
                                      });
                                    },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text(
                                'View Product',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 10,
                                ),
                                backgroundColor: ThemeColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            );
                          }),
                          buildRow('Remove', (item) {
                            final productId =
                                (item['productId'] ?? item['_id'] ?? item['id'])
                                    ?.toString();
                            final shopId =
                                (item['shopId'] ??
                                        item['ownerId'] ??
                                        item['shop'])
                                    ?.toString();

                            return IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: productId == null || shopId == null
                                  ? null
                                  : () async {
                                      await onRemove(productId, shopId);
                                    },
                              tooltip: 'Remove from comparison',
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close Comparison'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
