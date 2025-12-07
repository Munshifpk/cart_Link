import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:cart_link/Customer/customer_home.dart';
import 'package:cart_link/services/auth_state.dart';
import 'package:cart_link/Customer/shop_products_page.dart';
import 'package:cart_link/Customer/product_purchase_page.dart';
import 'package:cart_link/Customer/checkout_page.dart';
import 'package:cart_link/constant.dart';

class CustomerCartPage extends StatefulWidget {
  final Customer? customer;
  const CustomerCartPage({super.key, this.customer});

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _cartsByShop = {}; // Map<shopId, {shopData, items}>
  Map<String, String> _shopNames = {}; // Map<shopId, shopName>
  Map<String, bool> _updatingItems = {}; // Map<"shopId|productId", bool>

  @override
  void initState() {
    super.initState();
    _fetchCarts();
  }

  Future<void> _fetchShopName(String shopId) async {
    try {
      final response = await http
          .get(backendUri('$kApiShops/$shopId'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shopData = data['data'] ?? data;
        final shopName = shopData['shopName'] ?? 'Shop $shopId';

        if (mounted) {
          setState(() {
            _shopNames[shopId] = shopName;
          });
        }
      }
    } catch (e) {
      // Silently fail - use shop ID as fallback
      if (mounted) {
        setState(() {
          _shopNames[shopId] = 'Shop $shopId';
        });
      }
    }
  }

  Future<void> _fetchCarts() async {
    try {
      final customerId = AuthState.currentCustomer?['_id'];
      if (customerId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Not logged in. Please log in first.';
        });
        return;
      }

      final response = await http
          .get(backendUri('$kApiCart/customer/$customerId'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final carts = jsonData['data'] as List? ?? [];

        // Group carts by shop and organize data
        final Map<String, dynamic> shopMap = {};
        final Set<String> shopIds = {};

        for (var cart in carts) {
          final shopId = cart['shopId'] as String?;
          final items = cart['items'] as List? ?? [];

          if (shopId != null && items.isNotEmpty) {
            shopIds.add(shopId);

            if (!shopMap.containsKey(shopId)) {
              shopMap[shopId] = {
                'shopId': shopId,
                'items': [],
                'totalAmount': 0.0,
                'totalQuantity': 0,
              };
            }

            for (var item in items) {
              final productData = item['productId'];
              final quantity = item['quantity'] ?? 1;

              double price = 0.0;
              String productName = 'Unknown Product';

              if (productData is Map<String, dynamic>) {
                price = (productData['price'] ?? 0.0).toDouble();
                productName = productData['name'] ?? 'Unknown Product';
              }

              final itemTotal = price * quantity;
              shopMap[shopId]['items'].add({
                'productId': item['productId'] is Map
                    ? item['productId']['_id']
                    : item['productId'],
                'productName': productName,
                'quantity': quantity,
                'price': price,
                'total': itemTotal,
              });

              shopMap[shopId]['totalAmount'] += itemTotal;
              shopMap[shopId]['totalQuantity'] += quantity;
            }
          }
        }

        // Fetch shop names for all shops in parallel
        for (var shopId in shopIds) {
          _fetchShopName(shopId);
        }

        setState(() {
          _cartsByShop = shopMap;
          _isLoading = false;
          _errorMessage = shopMap.isEmpty ? 'Your cart is empty' : null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load cart. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _changeItemQuantity(
    String shopId,
    String productId,
    int newQuantity,
  ) async {
    final customerId = AuthState.currentCustomer?['_id'];
    if (customerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to update cart')),
        );
      }
      return;
    }

    final key = '$shopId|$productId';
    setState(() => _updatingItems[key] = true);

    try {
      final uri = backendUri('$kApiCart/$customerId/$shopId/item/$productId');
      final response = await http
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'quantity': newQuantity}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        // Update local state to reflect new quantity
        final shop = _cartsByShop[shopId] as Map<String, dynamic>?;
        if (shop != null) {
          final items = shop['items'] as List<dynamic>;
          final idx = items.indexWhere((it) => it['productId'] == productId);
          if (idx != -1) {
            // capture old item for undo
            final removedItem = Map<String, dynamic>.from(items[idx]);
            final oldQty = (removedItem['quantity'] ?? 0) as int;
            final productLabel = removedItem['productName'] ?? productId;

            if (newQuantity > 0) {
              final price = (items[idx]['price'] ?? 0).toDouble();
              items[idx]['quantity'] = newQuantity;
              items[idx]['total'] = price * newQuantity;
            } else {
              items.removeAt(idx);
            }

            // recalc totals
            double totalAmount = 0.0;
            int totalQuantity = 0;
            for (var it in items) {
              totalAmount += (it['total'] ?? 0).toDouble();
              totalQuantity += (it['quantity'] ?? 0) as int;
            }

            if (items.isEmpty) {
              _cartsByShop.remove(shopId);
            } else {
              shop['items'] = items;
              shop['totalAmount'] = totalAmount;
              shop['totalQuantity'] = totalQuantity;
              _cartsByShop[shopId] = shop;
            }

            if (mounted) setState(() {});

            // If item was removed, show undo snackbar with optimistic restore
            if (newQuantity <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed $productLabel from cart'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () async {
                      // Optimistically restore item locally immediately
                      final shopExists = _cartsByShop.containsKey(shopId);
                      if (!shopExists) {
                        _cartsByShop[shopId] = {
                          'shopId': shopId,
                          'items': [],
                          'totalAmount': 0.0,
                          'totalQuantity': 0,
                        };
                      }

                      final shopLocal =
                          _cartsByShop[shopId] as Map<String, dynamic>;
                      final itemsLocal = shopLocal['items'] as List<dynamic>;

                      // avoid duplicate re-insert if user presses UNDO multiple times
                      final exists = itemsLocal.any(
                        (it) => it['productId'] == productId,
                      );
                      if (!exists) {
                        itemsLocal.add({
                          'productId': productId,
                          'productName': removedItem['productName'],
                          'quantity': oldQty,
                          'price': removedItem['price'],
                          'total': (removedItem['price'] ?? 0) * oldQty,
                        });
                      }

                      // recalc totals locally
                      double totalAmount = 0.0;
                      int totalQuantity = 0;
                      for (var it in itemsLocal) {
                        totalAmount += (it['total'] ?? 0).toDouble();
                        totalQuantity += (it['quantity'] ?? 0) as int;
                      }

                      shopLocal['items'] = itemsLocal;
                      shopLocal['totalAmount'] = totalAmount;
                      shopLocal['totalQuantity'] = totalQuantity;
                      _cartsByShop[shopId] = shopLocal;
                      if (mounted) setState(() {});

                      // Fire restore request in background; revert if it fails
                      try {
                        final postUri = backendUri(kApiCart);
                        final body = jsonEncode({
                          'customerId': customerId,
                          'shopId': shopId,
                          'items': [
                            {'productId': productId, 'quantity': oldQty},
                          ],
                        });
                        final postResp = await http
                            .post(
                              postUri,
                              headers: {'Content-Type': 'application/json'},
                              body: body,
                            )
                            .timeout(const Duration(seconds: 12));

                        if (!(postResp.statusCode == 200 ||
                            postResp.statusCode == 201)) {
                          // revert local restore
                          final shop =
                              _cartsByShop[shopId] as Map<String, dynamic>?;
                          if (shop != null) {
                            final items = shop['items'] as List<dynamic>;
                            items.removeWhere(
                              (it) => it['productId'] == productId,
                            );
                            if (items.isEmpty) {
                              _cartsByShop.remove(shopId);
                            } else {
                              double ta = 0.0;
                              int tq = 0;
                              for (var it in items) {
                                ta += (it['total'] ?? 0).toDouble();
                                tq += (it['quantity'] ?? 0) as int;
                              }
                              shop['items'] = items;
                              shop['totalAmount'] = ta;
                              shop['totalQuantity'] = tq;
                              _cartsByShop[shopId] = shop;
                            }
                            if (mounted) setState(() {});
                          }

                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to restore item'),
                              ),
                            );
                        } else {
                          // success - optionally refresh to get server canonical data
                        }
                      } catch (e) {
                        // revert local restore on error
                        final shop =
                            _cartsByShop[shopId] as Map<String, dynamic>?;
                        if (shop != null) {
                          final items = shop['items'] as List<dynamic>;
                          items.removeWhere(
                            (it) => it['productId'] == productId,
                          );
                          if (items.isEmpty) {
                            _cartsByShop.remove(shopId);
                          } else {
                            double ta = 0.0;
                            int tq = 0;
                            for (var it in items) {
                              ta += (it['total'] ?? 0).toDouble();
                              tq += (it['quantity'] ?? 0) as int;
                            }
                            shop['items'] = items;
                            shop['totalAmount'] = ta;
                            shop['totalQuantity'] = tq;
                            _cartsByShop[shopId] = shop;
                          }
                          if (mounted) setState(() {});
                        }

                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error restoring item: $e')),
                          );
                      }
                    },
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update item: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating item: $e')));
      }
    } finally {
      if (mounted) setState(() => _updatingItems.remove(key));
    }
  }

  Future<void> _deleteShopCart(String shopId) async {
    final customerId = AuthState.currentCustomer?['_id'];
    if (customerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to modify cart')),
        );
      }
      return;
    }

    try {
      final uri = backendUri('$kApiCart/$customerId/$shopId');
      final resp = await http.delete(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        // remove locally
        if (_cartsByShop.containsKey(shopId)) {
          _cartsByShop.remove(shopId);
          if (mounted) setState(() {});
        }
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Shop cart deleted')));
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete shop cart: ${resp.statusCode}'),
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting shop cart: $e')));
    }
  }

  double _getGrandTotal() {
    double total = 0.0;
    for (var shop in _cartsByShop.values) {
      total += shop['totalAmount'] as double;
    }
    return total;
  }

  int _getTotalItems() {
    int total = 0;
    for (var shop in _cartsByShop.values) {
      total += shop['totalQuantity'] as int;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double s = width < 360 ? 0.85 : (width < 800 ? 1.0 : 1.05);
    
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : (_errorMessage != null && _cartsByShop.isEmpty)
            ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchCarts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        : _buildCartContent(width, s);

    return content;
  }

  Widget _buildCartContent(double width, double s) {

    final listView = RefreshIndicator(
      onRefresh: _fetchCarts,
      child: ListView(
        key: const PageStorageKey('cart'),
        padding: EdgeInsets.all(12 * s),
        children: [
          if (_cartsByShop.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cart (${_getTotalItems()} items)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${_cartsByShop.length} shop(s)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Refresh',
                        icon: const Icon(Icons.refresh),
                        onPressed: _fetchCarts,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ..._cartsByShop.entries.map((shopEntry) {
            final shopId = shopEntry.key;
            final shopData = shopEntry.value as Map<String, dynamic>;
            final items = shopData['items'] as List? ?? [];
            final totalAmount = shopData['totalAmount'] as double? ?? 0.0;
            final totalQuantity = shopData['totalQuantity'] as int? ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop header
                  Padding(
                    padding: EdgeInsets.all(16 * s),
                    child: Row(
                      children: [
                        Icon(Icons.store, color: Colors.blue, size: 24 * s),
                        SizedBox(width: 12 * s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    final response = await http
                                        .get(
                                          Uri.parse(
                                            backendUrl('$kApiShops/$shopId'),
                                          ),
                                        )
                                        .timeout(const Duration(seconds: 8));
                                    if (response.statusCode == 200) {
                                      final shopData =
                                          jsonDecode(response.body)['data'] ??
                                          jsonDecode(response.body);
                                      if (mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ShopProductsPage(
                                                  shop: shopData,
                                                ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error loading shop: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  _shopNames[shopId] ?? 'Shop $shopId',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Text(
                                '$totalQuantity item(s)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Delete shop cart button
                        IconButton(
                          tooltip: 'Delete shop cart',
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20 * s,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dctx) => AlertDialog(
                                title: const Text('Delete shop cart'),
                                content: Text(
                                  'Remove all items from ${_shopNames[shopId] ?? 'this shop'}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dctx).pop(true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _deleteShopCart(shopId);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),

                  // Items table header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Product',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Qty',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Rate',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Items list
                  ...items.asMap().entries.map((entry) {
                    final item = entry.value as Map<String, dynamic>;
                    final productName = item['productName'] ?? 'Unknown';
                    final quantity = item['quantity'] ?? 1;
                    final price = item['price'] ?? 0.0;
                    final itemTotal = item['total'] ?? 0.0;

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: 0.0,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        key: ValueKey(
                          productName + item['productId'].toString(),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * s,
                          vertical: 8 * s,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: GestureDetector(
                                onTap: () async {
                                  final productId =
                                      item['productId']?.toString() ?? '';
                                  try {
                                    final response = await http
                                        .get(
                                          Uri.parse(
                                            backendUrl(kApiProducts, queryParameters: {'ownerId': shopId}),
                                          ),
                                        )
                                        .timeout(const Duration(seconds: 8));
                                    if (response.statusCode == 200) {
                                      final productsData =
                                          jsonDecode(response.body)['data']
                                              as List? ??
                                          [];
                                      final productData = productsData
                                          .firstWhere(
                                            (p) =>
                                                p['_id']?.toString() ==
                                                    productId ||
                                                p['_id'] == productId,
                                            orElse: () => null,
                                          );

                                      if (productData != null && mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductPurchasePage(
                                                  offer: productData,
                                                ),
                                          ),
                                        );
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Product not found'),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to load product details',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error loading product: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  productName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13 * s,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Builder(
                                  builder: (ctx) {
                                    final productId =
                                        item['productId']?.toString() ?? '';
                                    final key = '$shopId|$productId';
                                    final isUpdating =
                                        _updatingItems[key] ?? false;
                                    return FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 34 * s,
                                            height: 34 * s,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: isUpdating
                                                  ? null
                                                  : () async {
                                                      final newQty =
                                                          (quantity as int) - 1;
                                                      if (newQty <= 0) {
                                                        final shouldRemove = await showDialog<bool>(
                                                          context: ctx,
                                                          builder: (dctx) => AlertDialog(
                                                            title: const Text(
                                                              'Remove item',
                                                            ),
                                                            content: Text(
                                                              'Remove "$productName" from your cart?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                      dctx,
                                                                    ).pop(
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                      dctx,
                                                                    ).pop(true),
                                                                child: const Text(
                                                                  'Remove',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                        if (shouldRemove ==
                                                            true) {
                                                          _changeItemQuantity(
                                                            shopId,
                                                            productId,
                                                            0,
                                                          );
                                                        }
                                                      } else {
                                                        _changeItemQuantity(
                                                          shopId,
                                                          productId,
                                                          newQty,
                                                        );
                                                      }
                                                    },
                                              child: const Icon(
                                                Icons.remove,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8 * s),
                                          SizedBox(
                                            width: 36 * s,
                                            child: isUpdating
                                                ? SizedBox(
                                                    width: 20 * s,
                                                    height: 20 * s,
                                                    child:
                                                        const CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : Text(
                                                    '$quantity',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 13 * s,
                                                    ),
                                                  ),
                                          ),
                                          SizedBox(width: 8 * s),
                                          SizedBox(
                                            width: 34 * s,
                                            height: 34 * s,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: isUpdating
                                                  ? null
                                                  : () {
                                                      final newQty =
                                                          (quantity as int) + 1;
                                                      _changeItemQuantity(
                                                        shopId,
                                                        productId,
                                                        newQty,
                                                      );
                                                    },
                                              child: Icon(
                                                Icons.add,
                                                size: 18 * s,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '₹${price.toStringAsFixed(2)}',
                                textAlign: TextAlign.end,
                                style: TextStyle(fontSize: 13 * s),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '₹${itemTotal.toStringAsFixed(2)}',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13 * s,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Shop total row
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16 * s,
                      12 * s,
                      16 * s,
                      16 * s,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12 * s,
                        horizontal: 12 * s,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shop Total:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * s,
                            ),
                          ),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16 * s,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Checkout button for this shop
                  Padding(
                    padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 16 * s),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48 * s,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8 * s),
                          ),
                        ),
                        onPressed: () {
                          final shopName = _shopNames[shopId] ?? 'Shop $shopId';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutPage(
                                shopId: shopId,
                                shopName: shopName,
                                items: List.from(items),
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.payment, size: 20 * s),
                        label: Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 14 * s,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Grand total row (only show inside list on small screens)
          if (_cartsByShop.isNotEmpty && width < 800)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Shops',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '${_cartsByShop.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Items',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '${_getTotalItems()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${_getGrandTotal().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );

    // Totals panel to show on the right for wide screens
    final totalsPanel = Container(
      width: math.min(360, width * 0.33),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Summary',
            style: TextStyle(fontSize: 18 * s, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shops',
                        style: TextStyle(
                          fontSize: 14 * s,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${_cartsByShop.length}',
                        style: TextStyle(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Items',
                        style: TextStyle(
                          fontSize: 14 * s,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${_getTotalItems()}',
                        style: TextStyle(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 16 * s,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${_getGrandTotal().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18 * s,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (width >= 800) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: listView),
            const SizedBox(width: 16),
            totalsPanel,
          ],
        ),
      );
    }

    return listView;
  }
}
