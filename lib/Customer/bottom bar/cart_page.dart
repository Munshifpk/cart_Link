import 'package:flutter/material.dart';
import '../customer_home.dart';

class CustomerCartPage extends StatelessWidget {
  final Customer? customer;
  const CustomerCartPage({super.key, this.customer});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const PageStorageKey('cart'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          const Text('Your cart is empty', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => {}, child: const Text('Shop now')),
        ],
      ),
    );
  }
}
