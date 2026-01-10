import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cart_link/services/auth_state.dart';
import 'shop_products_page.dart';
import '../theme_data.dart';
import 'package:cart_link/constant.dart';

class FollowedShopsPage extends StatefulWidget {
  final String? customerId;
  const FollowedShopsPage({super.key, this.customerId});

  @override
  State<FollowedShopsPage> createState() => _FollowedShopsPageState();
}

class _FollowedShopsPageState extends State<FollowedShopsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _shops = [];

  @override
  void initState() {
    super.initState();
    _loadFollowedShops();
  }

  Future<void> _loadFollowedShops() async {
    final customerId = widget.customerId?.trim().isNotEmpty == true
        ? widget.customerId!.trim()
        : (AuthState.currentCustomer?['_id']?.toString() ?? '');

    if (customerId.isEmpty) {
      setState(() {
        _loading = false;
        _shops = [];
      });
      return;
    }

    try {
      setState(() => _loading = true);
      final uri = backendUri('$kApiCustomers/$customerId/following');
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final shops = (data['data']?['shops'] as List? ?? [])
            .map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s))
            .toList();

        final enriched = await Future.wait(shops.map(_attachProductCount));
        if (!mounted) return;
        setState(() {
          _shops = enriched;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _shops = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load followed shops: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> _attachProductCount(Map<String, dynamic> shop) async {
    final shopId = (shop['_id'] ?? shop['id'] ?? '').toString();
    int count = 0;
    if (shopId.isNotEmpty) {
      try {
        final resp = await http
          .get(backendUri(kApiProducts, queryParameters: {'ownerId': shopId}))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final products = (data['data'] as List? ?? []);
          count = products.length;
        }
      } catch (_) {
        count = 0;
      }
    }
    shop['productCount'] = count;
    return shop;
  }

  Future<void> _confirmUnfollow(Map<String, dynamic> shop) async {
    final shopName = (shop['shopName'] ?? shop['name'] ?? 'this shop').toString();
    final shouldUnfollow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unfollow shop?'),
        content: Text('Stop following $shopName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );

    if (shouldUnfollow == true) {
      await _setFollow(shop, false, showUndo: true);
    }
  }

  Future<void> _setFollow(
    Map<String, dynamic> shop,
    bool isFollowing, {
    bool showUndo = false,
  }) async {
    final customerId = widget.customerId?.trim().isNotEmpty == true
        ? widget.customerId!.trim()
        : (AuthState.currentCustomer?['_id']?.toString() ?? '');
    if (customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to manage follows')),
      );
      return;
    }

    final shopId = (shop['_id'] ?? shop['id'] ?? '').toString();
    final shopName = (shop['shopName'] ?? shop['name'] ?? 'Shop').toString();
    if (shopId.isEmpty) return;

    try {
      final uri = backendUri('$kApiCustomers/follow-shop');
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'customerId': customerId,
              'shopId': shopId,
              'shopName': shopName,
              'isFollowing': isFollowing,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final messenger = ScaffoldMessenger.of(context);
        if (!isFollowing) {
          setState(() {
            _shops.removeWhere((s) => (s['_id'] ?? s['id']).toString() == shopId);
          });
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text('Unfollowed $shopName'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await _setFollow(shop, true);
                  await _loadFollowedShops();
                },
              ),
            ),
          );
        } else {
          final enriched = await _attachProductCount(Map<String, dynamic>.from(shop));
          setState(() {
            final idx = _shops.indexWhere(
              (s) => (s['_id'] ?? s['id']).toString() == shopId,
            );
            if (idx >= 0) {
              _shops[idx] = enriched;
            } else {
              _shops.insert(0, enriched);
            }
          });
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text('Following $shopName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update follow for $shopName')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating follow: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops You Follow'),
        elevation: 1,
        backgroundColor: ThemeColors.primary,
        foregroundColor: ThemeColors.textColorWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFollowedShops,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFollowedShops,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _shops.isEmpty
                ?  ListView(
                    children: [
                      SizedBox(height: 120),
                      Center(child: Text('You are not following any shops yet.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _shops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      final shopName = (shop['shopName'] ?? shop['name'] ?? 'Shop').toString();
                      final location = (shop['location'] ?? shop['address'] ?? 'Location not provided').toString();
                      final productsValue = shop['productCount'] ?? 0;
                      final products = productsValue is num
                          ? productsValue.toInt()
                          : int.tryParse(productsValue.toString()) ?? 0;

                      return Card(
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ShopProductsPage(shop: shop),
                              ),
                            );
                          },
                          title: Text(shopName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Location: $location'),
                              Text('Products: $products'),
                            ],
                          ),
                          trailing: TextButton(
                            onPressed: () => _confirmUnfollow(shop),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green.shade50,
                              foregroundColor: Colors.green.shade800,
                            ),
                            child: const Text('Following'),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
