import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cart_link/Customer/product_purchase_page.dart';
import 'package:cart_link/services/auth_state.dart';

class ShopNotificationsPage extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopNotificationsPage({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopNotificationsPage> createState() => _ShopNotificationsPageState();
}

class _ShopNotificationsPageState extends State<ShopNotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  String get _backendBase {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  @override
  void initState() {
    super.initState();
    _fetchShopNotifications();
  }

  Future<void> _fetchShopNotifications() async {
    try {
      setState(() => _isLoading = true);
      final uri = Uri.parse(
        '$_backendBase/api/shop-notifications?shopId=${widget.shopId}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> notificationsList =
            (body is Map && body.containsKey('data'))
            ? (body['data'] as List<dynamic>)
            : (body is List ? body : []);

        if (mounted) {
          setState(() {
            _notifications = notificationsList
                .map((n) => Map<String, dynamic>.from(n as Map))
                .toList();
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load shop notifications';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading notifications: $e';
        });
      }
    }
  }

  Future<bool> _quickAddToCart(Map<String, dynamic> notification) async {
    try {
      final productId = notification['productId'] ?? notification['_id'];
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];

      if (customerId == null || productId == null) return false;

      final body = jsonEncode({
        'productId': productId,
        'customerId': customerId,
        'shopId': widget.shopId,
        'quantity': 1,
      });

      final uri = Uri.parse('$_backendBase/api/cart');
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.shopName} - Offers & Stock'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchShopNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _notifications.isEmpty
          ? const Center(child: Text('No new offers o'))
          : SafeArea(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(12),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final notification = _notifications[i];
                    final image = (notification['image'] is String)
                        ? (notification['image'] as String)
                        : '';
                    final type =
                        notification['type'] ?? 'update'; // 'offer' or 'stock'
                    final isOffer = type == 'offer';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductPurchasePage(offer: notification),
                          ),
                        );
                      },
                      onLongPress: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Adding to cart...')),
                        );
                        final ok = await _quickAddToCart(notification);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? 'Added to cart' : 'Failed to add to cart',
                              ),
                            ),
                          );
                        }
                      },
                      child: ListTile(
                        leading: image.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  image,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => CircleAvatar(
                                    child: Icon(
                                      isOffer
                                          ? Icons.local_offer
                                          : Icons.inventory,
                                    ),
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: isOffer
                                    ? Colors.orange.shade50
                                    : Colors.green.shade50,
                                child: Icon(
                                  isOffer ? Icons.local_offer : Icons.inventory,
                                  color: isOffer ? Colors.orange : Colors.green,
                                ),
                              ),
                        title: Text(
                          notification['product'] ??
                              notification['productName'] ??
                              'Product',
                        ),
                        subtitle: Text(
                          isOffer
                              ? 'Special Offer • ${notification['discount'] ?? 0}% OFF'
                              : 'Back in stock • Available now',
                          style: TextStyle(
                            color: isOffer ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${notification['price'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isOffer)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'HOT',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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
            ),
    );
  }
}
