import 'package:flutter/material.dart';
import '../customer_home.dart';

class CustomerProductsPage extends StatelessWidget {
  final Customer? customer;
  const CustomerProductsPage({super.key, this.customer});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('category'),
      padding: const EdgeInsets.all(16),
      children: List.generate(
        8,
        (i) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text('Category ${i + 1}'),
            subtitle: const Text('Tap to view'),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
