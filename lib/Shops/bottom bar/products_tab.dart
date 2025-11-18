import 'package:flutter/material.dart';

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // NOTE: this is now a plain page (no Scaffold / FAB).
    // FAB is shown by the parent only when Products tab is active.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Products Coming Soon',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
