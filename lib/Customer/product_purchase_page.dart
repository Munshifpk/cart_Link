import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme_data.dart';

class ProductPurchasePage extends StatefulWidget {
  final Map<String, dynamic> offer;
  const ProductPurchasePage({super.key, required this.offer});

  @override
  State<ProductPurchasePage> createState() => _ProductPurchasePageState();
}

class _ProductPurchasePageState extends State<ProductPurchasePage> {
  late final ValueNotifier<int> _quantityNotifier;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _quantityNotifier = ValueNotifier<int>(1);
  }

  @override
  void dispose() {
    _quantityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final images = (offer['images'] is List) ? (offer['images'] as List).cast<String>() : <String>[];
    final mainImage = images.isNotEmpty ? images[_selectedImageIndex] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Product'),
      foregroundColor: ThemeColors.textColorWhite,
      backgroundColor: ThemeColors.primary
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          Widget thumbnails(double height) => SizedBox(
                height: height,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImageIndex = index),
                      child: Container(
                        width: height,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedImageIndex == index
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: _selectedImageIndex == index ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child: _buildImageWidget(images[index]),
                      ),
                    );
                  },
                ),
              );

          if (isWide) {
            // Side-by-side: image left, details right. Description full-width below.
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: big image + thumbnails
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Container(
                              height: 460,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: mainImage != null
                                  ? _buildImageWidget(mainImage)
                                  : const Icon(Icons.image, size: 120, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            if (images.isNotEmpty) thumbnails(90),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right: product summary and actions
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // name, price, mrp, shop
                            Text(
                              offer['product'] ?? 'Product',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Shop: ${offer['shop'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            // Price and MRP (MRP shown below price when available)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${offer['price'] ?? 0}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                const SizedBox(height: 6),
                                if ((offer['mrp'] ?? 0) > (offer['price'] ?? 0))
                                  Text(
                                    'MRP: ₹${(offer['mrp'] ?? 0).toString()}',
                                    style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 14),
                                  ),
                                if ((offer['discount'] ?? 0) > 0) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                                    child: Text('${offer['discount']}% off', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Quantity
                            const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    final newVal = (_quantityNotifier.value - 1) < 1 ? 1 : (_quantityNotifier.value - 1);
                                    _quantityNotifier.value = newVal;
                                  },
                                  child: const Text('-'),
                                ),
                                const SizedBox(width: 16),
                                ValueListenableBuilder<int>(
                                  valueListenable: _quantityNotifier,
                                  builder: (context, qty, _) => Text('$qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    final newVal = (_quantityNotifier.value + 1) > 100 ? 100 : (_quantityNotifier.value + 1);
                                    _quantityNotifier.value = newVal;
                                  },
                                  child: const Text('+'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Actions stacked vertically on wide screens
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      final qty = _quantityNotifier.value;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $qty item(s) to cart'), duration: const Duration(seconds: 2)));
                                      Future.delayed(const Duration(milliseconds: 500), () {
                                        if (context.mounted) Navigator.pushNamed(context, '/cart');
                                      });
                                    },
                                    icon: const Icon(Icons.shopping_cart, size: 24),
                                    label: const Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ThemeColors.accent,
                                      foregroundColor: ThemeColors.textColorWhite,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      final qty = _quantityNotifier.value;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Proceeding to checkout for $qty item(s)...'), duration: const Duration(seconds: 2)));
                                    },
                                    icon: const Icon(Icons.payment, size: 24),
                                    label: const Text('Buy Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ThemeColors.greenButton,
                                      foregroundColor: ThemeColors.textColorWhite,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description below spanning full width
                  const Text('Product Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text((offer['product'] ?? 'product').toString().toLowerCase() + ' — ' + (offer['description'] ?? 'High-quality product with excellent quality and durability.')),
                ],
              ),
            );
          }

          // Small screens: stacked layout (image -> thumbnails -> details)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: mainImage != null ? _buildImageWidget(mainImage) : const Icon(Icons.image, size: 100, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (images.isNotEmpty) thumbnails(80),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildProductDetails(offer))),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildProductDetails(Map<String, dynamic> offer) {
    return [
      // Product name and shop
      Text(
        offer['product'] ?? 'Product',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        'Shop: ${offer['shop'] ?? 'Unknown'}',
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      const SizedBox(height: 16),
      // Pricing
      Row(
        children: [
          Text(
            '₹${offer['price'] ?? 0}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          if ((offer['discount'] ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      const SizedBox(height: 16),
      // Valid till
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offer valid till',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    offer['validTill'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      // Quantity selector
      const Text(
        'Quantity',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          ElevatedButton(
            onPressed: () {
              final newVal = (_quantityNotifier.value - 1) < 1 ? 1 : (_quantityNotifier.value - 1);
              _quantityNotifier.value = newVal;
            },
            child: const Text('-'),
          ),
          const SizedBox(width: 16),
          ValueListenableBuilder<int>(
            valueListenable: _quantityNotifier,
            builder: (context, qty, _) => Text(
              '$qty',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              final newVal = (_quantityNotifier.value + 1) > 100 ? 100 : (_quantityNotifier.value + 1);
              _quantityNotifier.value = newVal;
            },
            child: const Text('+'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      // Description
      const Text(
        'Product Description',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'High-quality ${(offer['product'] ?? 'product').toLowerCase()} with excellent quality and durability. Perfect for everyday use.',
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      const SizedBox(height: 24),
      // Add to cart and buy now buttons (side by side for small screens)
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final qty = _quantityNotifier.value;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $qty item(s) to cart'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (context.mounted) {
                      Navigator.pushNamed(context, '/cart');
                    }
                  });
                },
                icon: const Icon(Icons.shopping_cart, size: 20),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.accent,
                  foregroundColor: ThemeColors.textColorWhite,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                ),
                label: const Text('Add to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final qty = _quantityNotifier.value;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Proceeding to checkout for $qty item(s)...',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.payment, size: 20),
                label: const Text('Buy Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.greenButton,
                  foregroundColor: ThemeColors.textColorWhite,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('data:')) {
      try {
        final parts = imageUrl.split(',');
        final b64 = parts.length > 1 ? parts.last : '';
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        );
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }
}
