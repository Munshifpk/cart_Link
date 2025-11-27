import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../customer_home.dart';
import 'shops_page.dart';
import '../shop_products_page.dart';

class CustomerHomePage extends StatefulWidget {
  final Customer? customer;
  const CustomerHomePage({super.key, this.customer});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _shops = [];

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      final resp = await http.get(Uri.parse('http://localhost:5000/api/Shops')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = (data['data'] as List? ?? []).map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s)).toList();
        // Fetch product counts for each shop in parallel
        final futures = list.map((shop) async {
          final shopId = shop['_id']?.toString() ?? '';
          int count = 0;
          if (shopId.isNotEmpty) {
            try {
              final resp2 = await http.get(Uri.parse('http://localhost:5000/api/products?ownerId=$shopId')).timeout(const Duration(seconds: 10));
              if (resp2.statusCode == 200) {
                final pData = jsonDecode(resp2.body);
                final products = (pData['data'] as List? ?? []);
                count = products.length;
              }
            } catch (_) {
              count = 0;
            }
          }
          shop['productCount'] = count;
          return shop;
        }).toList();

        final enriched = await Future.wait(futures);
        // sort by productCount desc and limit to top 6
        enriched.sort((a, b) => (b['productCount'] as int).compareTo(a['productCount'] as int));
        final top = enriched.take(6).toList();
        setState(() {
          _shops = top;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Widget _buildShopCardFromData(Map<String, dynamic> shop) {
    final name = (shop['shopName'] ?? shop['name'] ?? 'Shop').toString();
    final icon = shop['icon'] ?? '🏪';
    final rating = (shop['rating'] ?? 0).toString();
    final count = shop['productCount'] ?? 0;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ShopProductsPage(shop: shop)),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon.toString(), style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '$count products',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  rating,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('home'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Promo banner / carousel')),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recommended',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3 / 2,
            ),
            itemCount: 4,
            itemBuilder: (context, i) => Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('Item ${i + 1}')),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Shops',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopsPage()),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: List.generate(
                      _shops.isNotEmpty ? (_shops.length < 5 ? _shops.length : 5) : 0,
                      (i) => _buildShopCardFromData(_shops[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
