import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import '../customer_home.dart';
import 'shop_carts_page.dart';
import 'package:cart_link/services/auth_state.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchCarts();
  }

  String get _backendBase {
    if (kIsWeb) return 'http://localhost:5000';
    if (io.Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  Future<void> _fetchShopName(String shopId) async {
    try {
      final response = await http
          .get(Uri.parse('$_backendBase/api/Shops/$shopId'))
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
          .get(Uri.parse('$_backendBase/api/cart/customer/$customerId'))
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _cartsByShop.isEmpty) {
      return Center(
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
            ElevatedButton(onPressed: _fetchCarts, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCarts,
      child: ListView(
        key: const PageStorageKey('cart'),
        padding: const EdgeInsets.all(12),
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
                  Text(
                    '${_cartsByShop.length} shop(s)',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.store, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _shopNames[shopId] ?? 'Shop $shopId',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '$quantity',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '₹${price.toStringAsFixed(2)}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '₹${itemTotal.toStringAsFixed(2)}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Shop total row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shop Total:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Checkout button for this shop
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          final shopName = _shopNames[shopId] ?? 'Shop $shopId';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Proceeding to checkout for $shopName (₹${totalAmount.toStringAsFixed(2)})...',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          // TODO: Implement checkout flow
                        },
                        icon: const Icon(Icons.payment, size: 20),
                        label: const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 14,
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
          // Grand total row
          if (_cartsByShop.isNotEmpty)
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
                          'Total Items:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total:',
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
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Proceeding to checkout...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
