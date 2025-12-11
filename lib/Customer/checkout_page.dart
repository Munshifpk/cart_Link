import 'package:flutter/material.dart';
import '../theme_data.dart';
import '../services/order_service.dart';
import '../services/auth_state.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  final String? shopId; // null means all shops
  final String shopName;
  final List<dynamic>
  items; // list of item maps: {productId, productName, quantity, price, total}

  const CheckoutPage({
    super.key,
    this.shopId,
    required this.shopName,
    required this.items,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _processing = false;

  double _calcTotal() {
    double total = 0.0;
    for (var it in widget.items) {
      total += (it['total'] ?? 0).toDouble();
    }
    return total;
  }

  int _calcItems() {
    int t = 0;
    for (var it in widget.items) {
      t += (it['quantity'] ?? 0) as int;
    }
    return t;
  }

  Future<void> _confirmOrder() async {
    setState(() => _processing = true);

    final customerId = AuthState.currentCustomer?['_id'] ??
        AuthState.currentCustomer?['id'];

    if (customerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Customer not logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _processing = false);
      return;
    }

    // Prepare order data
    // Use the shopId passed to this page
    final shopId = widget.shopId;
    if (shopId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Shop ID is missing'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _processing = false);
      return;
    }

    // Build products list for this shop
    final products = widget.items.map((item) => {
      'productId': item['productId'],
      'quantity': item['quantity'] ?? 1,
      'price': item['price'] ?? 0.0,
      'mrp': item['mrp'],
    }).toList();

    // Create order (one customer, one shop)
    final result = await OrderService.createOrder(
      customerId: customerId,
      shopId: shopId,
      products: products,
    );

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      final orderId = result['data']['_id'] ?? result['data']['id'];
      if (orderId != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessPage(orderId: orderId),
          ),
        );
        // After success page, cart will be refreshed automatically
      }
    } else {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to place order',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcTotal();
    final totalItems = _calcItems();

    // compute totals based on MRP and selling price
    double subtotal = 0.0; // sum of selling price * qty
    double totalMrp = 0.0; // sum of mrp * qty
    double totalDiscount = 0.0; // sum of (mrp - price) * qty

    for (var raw in widget.items) {
      final it = raw as Map<String, dynamic>;
      final qty = (it['quantity'] ?? 0) is int
          ? (it['quantity'] ?? 0) as int
          : int.tryParse((it['quantity'] ?? '0').toString()) ?? 0;
      final priceRaw =
          it['price'] ?? it['sellingPrice'] ?? it['offerPrice'] ?? 0;
      final mrpRaw = it['mrp'] ?? it['MRP'] ?? it['listingMrp'] ?? priceRaw;
      final price = (priceRaw is num)
          ? priceRaw.toDouble()
          : double.tryParse(priceRaw.toString()) ?? 0.0;
      final mrp = (mrpRaw is num)
          ? mrpRaw.toDouble()
          : double.tryParse(mrpRaw.toString()) ?? price;

      subtotal += price * qty;
      totalMrp += mrp * qty;
      final disc = (mrp - price) > 0 ? (mrp - price) * qty : 0.0;
      totalDiscount += disc;
    }

    final grandTotal = double.parse(subtotal.toStringAsFixed(2));

    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          widget.shopId == null
              ? 'Checkout — All Shops'
              : 'Checkout — ${widget.shopName}',
        ),
        backgroundColor: ThemeColors.primary,
        foregroundColor: ThemeColors.textColorWhite,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                  ThemeColors.primary,
                  ThemeColors.accent.withOpacity(0.9),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalItems item(s)',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Make entire screen scrollable: items + summary + actions
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    if (widget.items.isEmpty) ...[
                      const SizedBox(height: 24),
                      const Center(child: Text('No items to checkout')),
                      const SizedBox(height: 24),
                    ] else
                      ...widget.items.map<Widget>((raw) {
                        final it = raw as Map<String, dynamic>;
                        final qty = (it['quantity'] ?? 0) is int
                            ? (it['quantity'] ?? 0) as int
                            : int.tryParse(
                                    (it['quantity'] ?? '0').toString(),
                                  ) ??
                                  0;
                        final priceRaw =
                            it['price'] ??
                            it['sellingPrice'] ??
                            it['offerPrice'] ??
                            0;
                        final mrpRaw =
                            it['mrp'] ??
                            it['MRP'] ??
                            it['listingMrp'] ??
                            priceRaw;
                        final price = (priceRaw is num)
                            ? priceRaw.toDouble()
                            : double.tryParse(priceRaw.toString()) ?? 0.0;
                        final mrp = (mrpRaw is num)
                            ? mrpRaw.toDouble()
                            : double.tryParse(mrpRaw.toString()) ?? price;
                        final lineTotal = price * qty;

                        return Column(
                          children: [
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            it['productName'] ??
                                                it['name'] ??
                                                'Product',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Qty: $qty  •  Price: ₹${price.toStringAsFixed(2)}  •  MRP: ₹${mrp.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          if ((mrp - price) > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Text(
                                                'You save: ₹${((mrp - price) * qty).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${lineTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),

                    // Order summary and actions now scroll with the items
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Visual calculation summary
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Subtotal'),
                                      Text('₹${subtotal.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total MRP'),
                                      Text('₹${totalMrp.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Discount'),
                                      Text(
                                        '-₹${totalDiscount.toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Grand Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '₹${grandTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _processing ? null : _confirmOrder,
                            icon: _processing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.payment),
                            label: Text(
                              _processing
                                  ? 'Processing...'
                                  : 'Confirm & Order ₹${grandTotal.toStringAsFixed(2)}',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: ThemeColors.primary,
                              foregroundColor: ThemeColors.textColorWhite,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _processing
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ThemeColors.primary,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }
}
