import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../theme_data.dart';
import '../../constant.dart';
import '../product_purchase_page.dart';
import '../../services/auth_state.dart';
import '../../services/order_service.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, List<dynamic>> _productReviews = {};
  bool _loadingReviews = false;
  Map<String, dynamic> _order = {};
  bool _loadingOrder = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _fetchOrderFromDatabase();
  }

  Future<void> _fetchOrderFromDatabase() async {
    try {
      setState(() => _loadingOrder = true);
      final orderId = widget.order['_id'] ?? widget.order['id'];
      if (orderId != null) {
        final result = await OrderService.getOrderById(orderId.toString());
        if (result['success'] == true && mounted) {
          setState(() {
            _order = result['data'] ?? widget.order;
            _loadingOrder = false;
          });
          _fetchAllProductReviews();
        } else {
          if (mounted) {
            setState(() {
              _loadingOrder = false;
              _order = widget.order;
            });
            _fetchAllProductReviews();
          }
        }
      } else {
        if (mounted) {
          setState(() => _loadingOrder = false);
          _fetchAllProductReviews();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingOrder = false);
        _fetchAllProductReviews();
      }
    }
  }

  Future<void> _fetchAllProductReviews() async {
    if (!mounted) return;
    setState(() => _loadingReviews = true);
    try {
      final products = (_order['products'] as List?) ?? [];
      final ids = <String>[];
      for (var p in products) {
        final prod = p['productId'];
        final productId = prod is Map ? (prod['_id'] ?? '') : '';
        if (productId.isNotEmpty) ids.add(productId);
      }

      final futures = ids.map((id) => _fetchReviews(id)).toList();
      final results = await Future.wait(futures);

      if (mounted) {
        final map = <String, List<dynamic>>{};
        for (var i = 0; i < ids.length; i++) {
          map[ids[i]] = results[i];
        }
        setState(() {
          _productReviews = map;
          _loadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<List<dynamic>> _fetchReviews(String productId) async {
    try {
      final uri = backendUri(
        '/api/reviews',
        queryParameters: {'productId': productId},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> list = body is Map && body.containsKey('data')
            ? (body['data'] as List<dynamic>)
            : (body is List ? body : []);
        return list;
      }
    } catch (_) {}
    return const [];
  }

  Future<void> _submitReview(
    String productId,
    int rating,
    String message,
    String? imageUrl,
  ) async {
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ?? AuthState.currentCustomer?['id'];
      final customerName = AuthState.currentCustomer?['name'] ?? 'Anonymous';
      if (customerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Login required')));
        }
        return;
      }
      final uri = backendUri('/api/reviews');
      final payload = {
        'productId': productId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
      };
      if (imageUrl != null && imageUrl.isNotEmpty)
        payload['imageUrl'] = imageUrl;
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Review submitted!')));
          await _fetchReviews(productId);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit review')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _submitCancellationFeedback(String feedback) async {
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ?? AuthState.currentCustomer?['id'];
      final customerName = AuthState.currentCustomer?['name'] ?? 'Anonymous';
      final orderId = _order['_id'] ?? _order['id'];
      if (customerId == null || orderId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to submit feedback')),
          );
        }
        return;
      }
      final uri = backendUri('/api/orders/$orderId/feedback');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'orderId': orderId,
              'customerId': customerId,
              'customerName': customerName,
              'feedback': feedback,
              'type': 'cancellation',
              'createdAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your feedback!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _contactShopWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
    }
  }

  Future<void> _showCallDialog(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Shop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phone Number:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(phone, style: const TextStyle(fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: cleanPhone));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number copied!'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Copy'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final uri = Uri(scheme: 'tel', path: cleanPhone);
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                } catch (e) {
                  print('Error making call: $e');
                }
              },
              icon: const Icon(Icons.call),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = _order['shopId'] is Map ? _order['shopId'] : null;
    final shopName = shop != null
        ? (shop['shopName'] ?? shop['name'] ?? 'Shop')
        : 'Shop';
    final shopPhone = shop != null
        ? ((_order['shopId']['contact'] ??
                  _order['shopId']['phone'] ??
                  _order['shopId']['mobile'] ??
                  '')
              .toString()
              .trim())
        : '';
    final status = _order['orderStatus'] ?? 'pending';
    final date = _order['createdAt'] != null
        ? _order['createdAt'].toString().replaceFirst('T', ' ').split('.').first
        : '';
    final total = (_order['totalAmount'] ?? 0).toDouble();
    final products = (_order['products'] as List?) ?? [];
    final deliveryAddress = (_order['deliveryAddress'] ?? '').toString();
    final otp = (_order['deliveryOtp'] ?? '').toString();
    final loc = _order['deliveryLocation'] is Map
        ? _order['deliveryLocation'] as Map<String, dynamic>
        : null;
    final lat = loc != null ? (loc['lat'] as num?)?.toDouble() : null;
    final lng = loc != null ? (loc['lng'] as num?)?.toDouble() : null;

    Color statusColor;
    switch (status) {
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'shipped':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: ThemeColors.primary,
        foregroundColor: ThemeColors.textColorWhite,
      ),
      body: _loadingOrder
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isBigDisplay = constraints.maxWidth > 900;
                  
                  if (isBigDisplay) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Order Items (60% width)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOrderItemsSection(products),
                              const SizedBox(height: 16),
                              _buildCancelledProductsSection(
                                (_order['cancelledProducts'] as List?) ?? [],
                              ),
                              const SizedBox(height: 16),
                              _buildReviewsSection(products),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right side: Details (40% width)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShopDetailsCard(shopName, shopPhone, status, statusColor, date),
                              const SizedBox(height: 12),
                              if (deliveryAddress.isNotEmpty || otp.isNotEmpty)
                                _buildDeliveryDetailsCard(deliveryAddress, lat, lng, otp),
                              const SizedBox(height: 12),
                              _buildActionButtonsCard(shopPhone, status),
                              const SizedBox(height: 12),
                              _buildTotalCard(total, products),
                              if (status == 'cancelled')
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showCancellationFeedbackDialog(context),
                                      icon: const Icon(Icons.feedback_outlined),
                                      label: const Text('Feedback'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShopDetailsCard(shopName, shopPhone, status, statusColor, date),
                        const SizedBox(height: 12),
                        if (deliveryAddress.isNotEmpty || otp.isNotEmpty)
                          _buildDeliveryDetailsCard(deliveryAddress, lat, lng, otp),
                        const SizedBox(height: 12),
                        _buildActionButtonsCard(shopPhone, status),
                        const SizedBox(height: 16),
                        _buildOrderItemsSection(products),
                        const SizedBox(height: 16),
                        _buildCancelledProductsSection(
                          (_order['cancelledProducts'] as List?) ?? [],
                        ),
                        const SizedBox(height: 16),
                        _buildTotalCard(total, products),
                        if (status == 'cancelled')
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showCancellationFeedbackDialog(context),
                                icon: const Icon(Icons.feedback_outlined),
                                label: const Text('Share Cancellation Feedback'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        _buildReviewsSection(products),
                      ],
                    );
                  }
                },
              ),
            ),
    );
  }

  Widget _buildShopDetailsCard(String shopName, String shopPhone, String status, Color statusColor, String date) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.store, color: Colors.deepOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (shopPhone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            shopPhone,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Divider(height: 12),
            Text('Order ID: ${_order['_id'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Date: $date', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsCard(String deliveryAddress, double? lat, double? lng, String otp) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (deliveryAddress.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.deepOrange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(deliveryAddress, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            if (lat != null && lng != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ),
            if (otp.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 14, color: Colors.deepOrange),
                    const SizedBox(width: 4),
                    Text('OTP: $otp', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsCard(String shopPhone, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: shopPhone.isNotEmpty ? () => _contactShopWhatsApp(shopPhone) : null,
          icon: const Icon(Icons.chat, size: 16),
          label: const Text('WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: shopPhone.isNotEmpty ? const Color(0xFF25D366) : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: shopPhone.isNotEmpty ? () => _showCallDialog(context, shopPhone) : null,
          icon: const Icon(Icons.call, size: 16),
          label: const Text('Call'),
          style: ElevatedButton.styleFrom(
            backgroundColor: shopPhone.isNotEmpty ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(double total, List<dynamic> products) {
    double computedGrandTotal = 0.0;
    final rows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(color: Colors.grey[100]),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Si.No', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      )
    ];

    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      final prod = p['productId'];
      final name = prod is Map ? (prod['name'] ?? 'Product') : (p['productName'] ?? 'Product');
      final qty = (p['quantity'] ?? 0) as int;
      final rate = ((p['price'] ?? 0) as num).toDouble();
      final lineTotal = rate * qty;
      computedGrandTotal += lineTotal;

      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('${i + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(name, style: const TextStyle(fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('₹${rate.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('₹${lineTotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(48),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(48),
                3: FixedColumnWidth(80),
                4: FixedColumnWidth(90),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: rows,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(
                  '₹${computedGrandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
            if ((total).toStringAsFixed(2) != computedGrandTotal.toStringAsFixed(2))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Note: Backend total ₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection(List<dynamic> products) {
    if (products.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No items in this order',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text(
                '${products.length} Item${products.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.deepOrange.withOpacity(0.2),
              labelStyle: const TextStyle(color: Colors.deepOrange),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...products.asMap().entries.map<Widget>((entry) {
          // final index = entry.key + 1;
          final p = entry.value;
          final prod = p['productId'];
          final productId = prod is Map ? (prod['_id'] ?? '') : '';
          final name = prod is Map ? (prod['name'] ?? 'Product') : 'Product';
          // final category = prod is Map ? (prod['category'] ?? '') : '';
          final qty = p['quantity'] ?? 0;
          final price = (p['price'] ?? 0).toDouble();
          final mrp = (p['mrp'] ?? price).toDouble();
          final discount = mrp > 0
              ? (((mrp - price) / mrp) * 100).toStringAsFixed(0)
              : '0';
          final itemTotal = price * qty;
          final reviews = _productReviews[productId] ?? [];
          final avgRating = reviews.isNotEmpty
              ? reviews.fold<double>(
                      0,
                      (sum, r) => sum + ((r['rating'] ?? 0) as num),
                    ) /
                    reviews.length
              : 0.0;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              onTap: productId.isNotEmpty
                  ? () => _showItemDetailsDialog(context, p, reviews, avgRating)
                  : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product image with styling
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildProductImage(prod),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Qty: $qty',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                              if (discount != '0') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$discount% OFF',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '₹${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (mrp > price) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '₹${mrp.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (reviews.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, size: 12, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        avgRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$qty × ₹${price.toStringAsFixed(2)} = ₹${itemTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Tap indicator
                    Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showItemDetailsDialog(
    BuildContext context,
    Map<String, dynamic> item,
    List<dynamic> reviews,
    double avgRating,
  ) {
    final prod = item['productId'];
    final productId = prod is Map ? (prod['_id'] ?? '') : '';
    final name = prod is Map ? (prod['name'] ?? 'Product') : 'Product';
    final description = prod is Map ? (prod['description'] ?? '') : '';
    final category = prod is Map ? (prod['category'] ?? '') : '';
    final qty = item['quantity'] ?? 0;
    final price = (item['price'] ?? 0).toDouble();
    final mrp = (item['mrp'] ?? price).toDouble();
    final discount = mrp > 0
        ? (((mrp - price) / mrp) * 100).toStringAsFixed(0)
        : '0';
    final itemTotal = price * qty;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Item Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (category.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Chip(
                    label: Text(category, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.deepOrange.withOpacity(0.2),
                  ),
                ),
              if (description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Price per item:', style: TextStyle(fontSize: 12)),
                  Text(
                    '₹${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MRP:', style: TextStyle(fontSize: 12)),
                  Text(
                    '₹${mrp.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:', style: TextStyle(fontSize: 12)),
                  Text(
                    '$discount% off',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity:', style: TextStyle(fontSize: 12)),
                  Text(
                    qty.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Item Total:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹${itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (reviews.isNotEmpty) ...[
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Customer Rating:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${avgRating.toStringAsFixed(1)} (${reviews.length})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Product ID: $productId',
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (productId.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final shopId = (_order['shopId'] is Map)
                    ? (_order['shopId']['_id'] ?? _order['shopId']['id'])
                    : _order['shopId'];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductPurchasePage(
                      offer: {
                        '_id': productId,
                        'shopId': shopId,
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCancelledProductsSection(List<dynamic> cancelled) {
    if (cancelled.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cancelled Items',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...cancelled.map<Widget>((c) {
          final prod = c['productId'];
          final productId = prod is Map
              ? (prod['_id'] ?? '')
              : (c['productId'] ?? '');
          final name = prod is Map
              ? (prod['name'] ?? c['productName'] ?? 'Product')
              : (c['productName'] ?? 'Product');
          final qty = c['quantity'] ?? 0;
          final price = (c['price'] ?? 0).toDouble();
          final cancelledAt = c['cancelledAt'] != null
              ? c['cancelledAt']
                    .toString()
                    .replaceFirst('T', ' ')
                    .split('.')
                    .first
              : '';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('Qty: $qty', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price: ₹${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        cancelledAt,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  if ((productId ?? '').toString().isNotEmpty && qty > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildReviewsSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    // Only show reviews section if order is delivered or completed
    final status = _order['orderStatus'] ?? 'pending';
    if (status != 'delivered' && status != 'completed') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews & Feedback',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_loadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ...products.map<Widget>((p) {
            final prod = p['productId'];
            final name = prod is Map ? (prod['name'] ?? 'Product') : 'Product';
            final productId = prod is Map ? (prod['_id'] ?? '') : '';
            if (productId.isEmpty) return const SizedBox.shrink();

            final reviews = _productReviews[productId] ?? [];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showWriteReviewDialog(context, productId, name),
                          icon: const Icon(Icons.rate_review, size: 16),
                          label: const Text('Write Review'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (reviews.isEmpty)
                      const Text(
                        'No reviews yet',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      )
                    else
                      ...reviews.map<Widget>((review) {
                        final author = review['customerId'] is Map
                            ? (review['customerId']['name'] ?? 'Anonymous')
                            : (review['customerName'] ?? 'Anonymous');
                        final rating = review['rating'] ?? 0;
                        final message = review['message'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    author,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 14,
                                        color: Colors.amber,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              if (message.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    message,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  void _showWriteReviewDialog(
    BuildContext context,
    String productId,
    String productName,
  ) {
    final customerId =
        AuthState.currentCustomer?['_id'] ?? AuthState.currentCustomer?['id'];
    if (customerId == null || customerId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to write a review')),
      );
      return;
    }

    int rating = 5;
    final messageCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text('Review $productName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Rating',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                        onPressed: () => setState(() => rating = i + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Your Review',
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageUrlCtrl,
                    decoration: InputDecoration(
                      labelText: 'Image URL (Optional)',
                      hintText: 'https://...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (messageCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please write a review')),
                    );
                    return;
                  }

                  await _submitReview(
                    productId,
                    rating,
                    messageCtrl.text,
                    imageUrlCtrl.text.isEmpty ? null : imageUrlCtrl.text,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review submitted successfully!'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCancellationFeedbackDialog(BuildContext context) {
    final feedbackCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancellation Feedback'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please let us know why you cancelled this order. Your feedback helps us improve.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackCtrl,
                decoration: InputDecoration(
                  labelText: 'Your Feedback',
                  hintText: 'Share your reason for cancellation...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (feedbackCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide feedback')),
                );
                return;
              }

              await _submitCancellationFeedback(feedbackCtrl.text);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  
  Widget _buildProductImage(dynamic prod) {
    // Prefer backend image by product id first
    if (prod is Map) {
      final productId = (prod['_id'] ?? prod['id'])?.toString();
      if (productId != null && productId.isNotEmpty) {
        try {
          final uri = backendUri('/api/products/$productId/image');
          return Image.network(
            uri.toString(),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange.withOpacity(0.5)),
                ),
              );
            },
            errorBuilder: (_, __, ___) {
              // Fallback to local fields if backend image not available
              String? imageUrlOrData;
              final images = (prod['images'] as List?) ?? [];
              if (images.isNotEmpty && images.first is String) {
                imageUrlOrData = images.first as String;
              } else if (prod['image'] is String) {
                imageUrlOrData = prod['image'] as String;
              }
              if (imageUrlOrData != null && imageUrlOrData.isNotEmpty) {
                final val = imageUrlOrData;
                if (val.startsWith('http')) {
                  return Image.network(val, fit: BoxFit.cover);
                }
              }
              return _buildImagePlaceholder();
            },
          );
        } catch (_) {}
      }
    }
    // Final fallback
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.grey[400], size: 28),
            const SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}