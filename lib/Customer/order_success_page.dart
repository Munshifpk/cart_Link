import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme_data.dart';


import '../services/order_service.dart';

class OrderSuccessPage extends StatefulWidget {
  final String orderId;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}


class _OrderSuccessPageState extends State<OrderSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  Map<String, dynamic>? orderData;
  bool loading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });
    final result = await OrderService.getOrderById(widget.orderId);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        orderData = result['data'];
        loading = false;
      });
    } else {
      setState(() {
        errorMsg = result['message'] ?? 'Failed to fetch order details';
        loading = false;
      });
    }
  }




  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ThemeColors.primary,
              ThemeColors.accent,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: loading
                ? const CircularProgressIndicator()
                : errorMsg != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            errorMsg!,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchOrder,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : _buildSuccessContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    if (orderData == null) return const SizedBox();
    final products = (orderData!['products'] as List?) ?? [];
    final totalAmount = orderData!['totalAmount'] ?? 0.0;
    final itemCount = products.fold<int>(0, (sum, p) => sum + ((p['quantity'] ?? 0) as int));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success animation
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 15,
                ),
              ],
            ),
            child: Lottie.asset(
              'assets/animations/success.json',
              repeat: false,
              delegates: LottieDelegates(
                values: [
                  ValueDelegate.color(
                    const ['**', 'circle', '**'],
                    value: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Success message
        ScaleTransition(
          scale: _scaleAnimation,
          child: const Text(
            'Order Placed Successfully!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Order details
        ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            children: [
              Text(
                '$itemCount item(s) • ₹${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your order is being processed',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // List products
              ...products.map<Widget>((p) {
                final prod = p['productId'];
                final name = prod is Map ? prod['name'] ?? 'Product' : 'Product';
                final qty = p['quantity'] ?? 0;
                final price = p['price'] ?? 0.0;
                final mrp = p['mrp'] ?? price;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$name',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'x$qty',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${price.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      if ((mrp - price) > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'MRP: ₹${mrp.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white54, decoration: TextDecoration.lineThrough),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 60),

        // Action buttons
        ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Pop twice: success page + checkout page to refresh cart
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ThemeColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                icon: const Icon(Icons.shopping_cart),
                label: const Text(
                  'Back to Cart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to orders page (implement later)
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('View Orders feature coming soon!'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.receipt_long),
                label: const Text(
                  'View Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
