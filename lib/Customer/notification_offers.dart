import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cart_link/Customer/app_updates_page.dart';
import 'package:cart_link/Customer/product_purchase_page.dart';
import 'package:cart_link/services/auth_state.dart';
import '../theme_data.dart';
import 'package:cart_link/constant.dart';

class OffersFollowedShopsPage extends StatefulWidget {
  const OffersFollowedShopsPage({super.key});

  @override
  State<OffersFollowedShopsPage> createState() =>
      _OffersFollowedShopsPageState();
}

class _OffersFollowedShopsPageState extends State<OffersFollowedShopsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      setState(() => _isLoading = true);
      final customerId =
          AuthState.currentCustomer?['_id'] ?? AuthState.currentCustomer?['id'];
      if (customerId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Customer not logged in';
        });
        return;
      }
      final uri = backendUri('$kApiNotifications/$customerId');
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
            _errorMessage = 'Failed to load notifications';
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

  // Future<bool> _quickAddToCart(Map<String, dynamic> offer) async {
  //   try {
  //     final shopId = offer['shopId'] ?? offer['ownerId'] ?? offer['shop'];
  //     final productId = offer['_id'] ?? offer['id'] ?? offer['productId'];
  //     final customerId =
  //         AuthState.currentCustomer?['_id'] ??
  //         AuthState.currentCustomer?['id'] ??
  //         AuthState.currentCustomer?['mobile'];

  //     if (customerId == null) return false;
  //     if (shopId == null || productId == null) return false;

  //     final body = jsonEncode({
  //       'productId': productId,
  //       'customerId': customerId,
  //       'shopId': shopId,
  //       'quantity': 1,
  //     });

  //     final uri = backendUri(kApiCart);
  //     final res = await http
  //         .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
  //         .timeout(const Duration(seconds: 10));
  //     return res.statusCode == 200 || res.statusCode == 201;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inMinutes}m ago';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications - Products'),
        foregroundColor: ThemeColors.textColorWhite,
        backgroundColor: ThemeColors.primary,
        actions: [
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
                    onPressed: _fetchNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _notifications.isEmpty
          ? const Center(child: Text('No notifications available'))
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
                    final isRead = notification['isRead'] ?? false;
                    return InkWell(
                      onTap: () async {
                        // Mark as read
                        final notificationId =
                            notification['_id'] ?? notification['id'];
                        if (notificationId != null && !isRead) {
                          try {
                            final uri = backendUri(
                              '$kApiNotifications/$notificationId/read',
                            );
                            await http.put(
                              uri,
                              headers: {'Content-Type': 'application/json'},
                            );
                            setState(() => notification['isRead'] = true);
                          } catch (e) {
                            // Ignore error
                          }
                        }
                        // If offer type, navigate to product
                        if (notification['type'] == 'offer' &&
                            notification['data'] != null) {
                          final productId = notification['data']['productId'];
                          if (productId != null) {
                            // Fetch product details
                            try {
                              final productUri = backendUri(
                                '$kApiProducts/$productId',
                              );
                              final res = await http.get(productUri);
                              if (res.statusCode == 200) {
                                final body = jsonDecode(res.body);
                                final product = body['data'];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductPurchasePage(offer: product),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Ignore
                            }
                          }
                        }
                      },
                      child: ListTile(
                        leading:
                            (notification['data'] != null &&
                                notification['data']['image'] != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  notification['data']['image'],
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    notification['type'] == 'offer'
                                        ? Icons.local_offer
                                        : Icons.notifications,
                                    color: isRead ? Colors.grey : Colors.blue,
                                  ),
                                ),
                              )
                            : Icon(
                                notification['type'] == 'offer'
                                    ? Icons.local_offer
                                    : Icons.notifications,
                                color: isRead ? Colors.grey : Colors.blue,
                              ),
                        title: Text(
                          notification['title'] ?? 'Notification',
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(notification['message'] ?? ''),
                        trailing: Text(
                          _formatDate(notification['createdAt']),
                          style: const TextStyle(fontSize: 12),
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
