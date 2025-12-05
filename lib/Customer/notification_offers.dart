import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cart_link/Customer/app_updates_page.dart';
import 'package:cart_link/Customer/product_purchase_page.dart';
import 'package:cart_link/services/auth_state.dart';

class OffersFollowedShopsPage extends StatefulWidget {
  const OffersFollowedShopsPage({super.key});

  @override
  State<OffersFollowedShopsPage> createState() =>
      _OffersFollowedShopsPageState();
}

class _OffersFollowedShopsPageState extends State<OffersFollowedShopsPage> {
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _offersEnabled = true;
  static const String _offersEnabledKey = 'offers_notifications_enabled';

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _fetchOffers();
  }

  String get _backendBase {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  get SharedPreferences => null;

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_offersEnabledKey);
    setState(() => _offersEnabled = enabled ?? true);
  }

  Future<void> _fetchOffers() async {
    try {
      setState(() => _isLoading = true);
      final uri = Uri.parse('$_backendBase/api/products');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> productsList =
            (body is Map && body.containsKey('data'))
            ? (body['data'] as List<dynamic>)
            : (body is List ? body : []);
        if (mounted) {
          setState(() {
            _offers = productsList
                .map((p) => Map<String, dynamic>.from(p as Map))
                .take(10)
                .toList();
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load offers';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading offers: $e';
        });
      }
    }
  }

  Future<bool> _quickAddToCart(Map<String, dynamic> offer) async {
    try {
      final shopId = offer['shopId'] ?? offer['ownerId'] ?? offer['shop'];
      final productId = offer['_id'] ?? offer['id'] ?? offer['productId'];
      final customerId =
          AuthState.currentCustomer?['_id'] ??
          AuthState.currentCustomer?['id'] ??
          AuthState.currentCustomer?['mobile'];

      if (customerId == null) return false;
      if (shopId == null || productId == null) return false;

      final body = jsonEncode({
        'productId': productId,
        'customerId': customerId,
        'shopId': shopId,
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
        title: const Text('Notifications - Offers'),
        actions: [
          IconButton(
            tooltip: 'Notification settings',
            icon: const Icon(Icons.tune),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Notification Preferences'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: const Text('Offers & Promotions'),
                        value: _offersEnabled,
                        onChanged: (val) async {
                          setState(() => _offersEnabled = val);
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(_offersEnabledKey, val);
                            if (val) _fetchOffers();
                          } catch (e) {
                            if (kDebugMode)
                              print('Error saving preference: $e');
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'App updates',
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppUpdatesPage()),
              );
            },
          ),
        ],
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
                    onPressed: _fetchOffers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _offers.isEmpty
          ? const Center(child: Text('No offers available'))
          : SafeArea(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(12),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _offers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final offer = _offers[i];
                    final image = (offer['image'] is String)
                        ? (offer['image'] as String)
                        : '';
                    // Safely get shop name for avatar and text
                    final shopName =
                        offer['shop'] ??
                        offer['shopName'] ??
                        offer['owner'] ??
                        '';
                    final shopInitial =
                        (shopName is String && shopName.isNotEmpty)
                        ? shopName[0]
                        : '?';
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductPurchasePage(offer: offer),
                          ),
                        );
                      },
                      onLongPress: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Adding to cart...')),
                        );
                        final ok = await _quickAddToCart(offer);
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
                                  errorBuilder: (_, __, ___) =>
                                      CircleAvatar(child: Text(shopInitial)),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Text(shopInitial),
                              ),
                        title: Text(
                          offer['product'] ?? offer['productName'] ?? 'Product',
                        ),
                        subtitle: Text(
                          '${shopName is String && shopName.isNotEmpty ? shopName : 'Shop'} • Valid till ${offer['validTill'] ?? 'N/A'}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${offer['price'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${offer['discount'] ?? 0}%',
                                style: const TextStyle(
                                  color: Colors.orange,
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
