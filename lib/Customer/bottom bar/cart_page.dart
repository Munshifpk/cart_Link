import 'package:flutter/material.dart';
import '../customer_home.dart';
import 'shop_carts_page.dart';

class CustomerCartPage extends StatefulWidget {
  final Customer? customer;
  const CustomerCartPage({super.key, this.customer});

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  @override
  Widget build(BuildContext context) {
    // Show list of example shops and navigate to their carts
    final shops = [
      'ExampleShop1',
      'ExampleShop2',
      'ExampleShop3',
      'ExampleShop4',
      'ExampleShop5',
    ];
    return ListView.builder(
      key: const PageStorageKey('cart'),
      padding: const EdgeInsets.all(12),
      itemCount: shops.length,
      itemBuilder: (context, i) {
        final shop = shops[i];
        return Card(
          child: ListTile(
            title: Text(shop),
            subtitle: const Text('Tap to manage carts for this shop'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShopCartsPage(shopName: shop),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
