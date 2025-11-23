import 'package:flutter/material.dart';
import '../customer_home.dart';

class CustomerHomePage extends StatelessWidget {
  final Customer? customer;
  const CustomerHomePage({super.key, this.customer});

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
        ],
      ),
    );
  }
}
