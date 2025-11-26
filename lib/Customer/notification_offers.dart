import 'package:flutter/material.dart';
import 'package:cart_link/Customer/app_updates_page.dart';
import 'package:cart_link/Customer/product_purchase_page.dart';

class OffersFollowedShopsPage extends StatelessWidget {
  const OffersFollowedShopsPage({super.key});

  // Sample data representing offers from shops the user follows
  final List<Map<String, dynamic>> _offers = const [
    {
      'shop': 'TechZone',
      'product': 'Wireless Headphones',
      'discount': 20,
      'price': 1999,
      'validTill': 'Dec 10, 2025',
    },
    {
      'shop': 'SoundMart',
      'product': 'Bluetooth Speaker',
      'discount': 25,
      'price': 1350,
      'validTill': 'Dec 05, 2025',
    },
    {
      'shop': 'GadgetHub',
      'product': 'Laptop Stand',
      'discount': 15,
      'price': 1020,
      'validTill': 'Dec 20, 2025',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications - Offers'),
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
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final offer = _offers[i];
          return ListTile(
            leading: CircleAvatar(child: Text(offer['shop'][0])),
            title: Text(offer['product']),
            subtitle: Text(
              '${offer['shop']} • Valid till ${offer['validTill']}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${offer['price']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                    '-${offer['discount']}%',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductPurchasePage(offer: offer),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
