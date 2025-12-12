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
    setState(() => _loadingReviews = true);
    final products = (_order['products'] as List?) ?? [];
    for (var p in products) {
      final prod = p['productId'];
      final productId = prod is Map ? (prod['_id'] ?? '') : '';
      if (productId.isNotEmpty) {
        await _fetchReviews(productId);
      }
    }
    setState(() => _loadingReviews = false);
  }

  Future<void> _fetchReviews(String productId) async {
    try {
      final uri = backendUri(
        '/api/reviews',
        queryParameters: {'productId': productId},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> list = body is Map && body.containsKey('data')
            ? (body['data'] as List<dynamic>)
            : (body is List ? body : []);
        setState(() {
          _productReviews[productId] = list;
        });
      }
    } catch (_) {}
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.store, color: Colors.deepOrange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (shopPhone.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Phone: $shopPhone',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Order ID: ${_order['_id'] ?? ''}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    'Date: $date',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  if (deliveryAddress.isNotEmpty || otp.isNotEmpty)
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Delivery Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (deliveryAddress.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.deepOrange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(deliveryAddress)),
                                ],
                              ),
                            if (lat != null && lng != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Coords: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            if (otp.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.lock,
                                      color: Colors.deepOrange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delivery OTP: $otp',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: shopPhone.isNotEmpty
                              ? () => _contactShopWhatsApp(shopPhone)
                              : null,
                          icon: const Icon(Icons.chat),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: shopPhone.isNotEmpty
                                ? const Color(0xFF25D366)
                                : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: shopPhone.isNotEmpty
                              ? () => _showCallDialog(context, shopPhone)
                              : null,
                          icon: const Icon(Icons.call),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: shopPhone.isNotEmpty
                                ? Colors.green
                                : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (status == 'cancelled')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showCancellationFeedbackDialog(context),
                          icon: const Icon(Icons.feedback_outlined),
                          label: const Text('Share Cancellation Feedback'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildOrderItemsSection(products),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  _buildCancelledProductsSection(
                    (_order['cancelledProducts'] as List?) ?? [],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildReviewsSection(products),
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
          final index = entry.key + 1;
          final p = entry.value;
          final prod = p['productId'];
          final productId = prod is Map ? (prod['_id'] ?? '') : '';
          final name = prod is Map ? (prod['name'] ?? 'Product') : 'Product';
          final category = prod is Map ? (prod['category'] ?? '') : '';
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
            child: InkWell(
              onTap: productId.isNotEmpty
                  ? () => _showItemDetailsDialog(context, p, reviews, avgRating)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              index.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (category.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.deepOrange,
                              ),
                            ),
                            if (mrp > price)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '₹${mrp.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                            if (mrp > price)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '$discount% off',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Qty: $qty',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (productId.isNotEmpty && (qty ?? 0) > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 18,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Remove 1',
                                      onPressed: () {
                                        _showRemoveOneConfirmation(
                                          context,
                                          productId.toString(),
                                          name,
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Total: ₹${itemTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (reviews.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${avgRating.toStringAsFixed(1)} (${reviews.length})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'No reviews',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Product ID: ${productId.substring(0, productId.length > 8 ? 8 : productId.length)}...',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                            if (productId.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: qty > 0
                                          ? () {
                                              _confirmCompleteProduct(
                                                context,
                                                productId,
                                                name,
                                                qty,
                                              );
                                            }
                                          : null,
                                      icon: const Icon(
                                        Icons.check_circle,
                                        size: 14,
                                      ),
                                      label: const Text('Complete'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Show Cancel (quantity-wise) only when order status allows
                                    Builder(
                                      builder: (ctx) {
                                        final orderStatus =
                                            _order['orderStatus'] ?? 'pending';
                                        final canCancel =
                                            orderStatus != 'delivered' &&
                                            orderStatus != 'cancelled' &&
                                            orderStatus != 'shipped';
                                        return ElevatedButton.icon(
                                          onPressed: (qty > 0 && canCancel)
                                              ? () {
                                                  _showCancelProductConfirmation(
                                                    context,
                                                    productId,
                                                    name,
                                                  );
                                                }
                                              : null,
                                          icon: const Icon(
                                            Icons.cancel,
                                            size: 14,
                                          ),
                                          label: const Text('Cancel'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: canCancel
                                                ? Colors.redAccent
                                                : Colors.grey,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
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
          // Cancel button removed from item details per request
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
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Attempt to restore the cancelled quantity
                              await _undoCancelProductByQuantity(
                                productId.toString(),
                                name,
                                qty,
                              );
                            },
                            icon: const Icon(
                              Icons.restore_from_trash,
                              size: 14,
                            ),
                            label: const Text('Restore'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
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

  void _showCancelProductConfirmation(
    BuildContext context,
    String productId,
    String productName,
  ) {
    // Find the product in the order to get available quantity
    int availableQty = 0;
    final products = (_order['products'] as List?) ?? [];
    for (var p in products) {
      final prod = p['productId'];
      final pId = prod is Map ? (prod['_id'] ?? '') : '';
      if (pId == productId) {
        availableQty = p['quantity'] ?? 0;
        break;
      }
    }

    int cancelQty = availableQty;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Cancel Product'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product: $productName',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'Available Quantity: $availableQty',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quantity to Cancel:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: cancelQty > 1
                          ? () => setState(() => cancelQty--)
                          : null,
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cancelQty.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: cancelQty < availableQty
                          ? () => setState(() => cancelQty++)
                          : null,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Note: This will cancel $cancelQty item${cancelQty > 1 ? 's' : ''} of this product.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No, Keep it'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _cancelProductByQuantity(
                    productId,
                    productName,
                    cancelQty,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRemoveOneConfirmation(
    BuildContext context,
    String productId,
    String productName,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove 1 Item'),
        content: Text(
          'Are you sure you want to remove 1 unit of "$productName" from this order? This will update the order in the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelProductByQuantity(productId, productName, 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Remove 1'),
          ),
        ],
      ),
    );
  }

  // Completion flow: allow marking product(s) as completed by quantity.
  void _confirmCompleteProduct(
    BuildContext context,
    String productId,
    String productName,
    int availableQty,
  ) {
    int completeQty = availableQty;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Mark Product Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product: $productName',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'Available Quantity: $availableQty',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Quantity to mark complete:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: completeQty > 1
                          ? () => setState(() => completeQty--)
                          : null,
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          completeQty.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: completeQty < availableQty
                          ? () => setState(() => completeQty++)
                          : null,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'This will mark $completeQty item${completeQty > 1 ? 's' : ''} as completed.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _completeProductByQuantity(
                    productId,
                    productName,
                    completeQty,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, Complete'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _completeProductByQuantity(
    String productId,
    String productName,
    int quantityToComplete,
  ) async {
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ?? AuthState.currentCustomer?['id'];
      final orderId = _order['_id'] ?? _order['id'];

      if (customerId == null || orderId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to process completion')),
          );
        }
        return;
      }

      final uri = backendUri('/api/orders/$orderId/complete-product');
      final payload = {
        'productId': productId,
        'productName': productName,
        'quantityToComplete': quantityToComplete,
        'customerId': customerId,
        'completedAt': DateTime.now().toIso8601String(),
      };

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          String? completedRecordId;
          int returnedQty = quantityToComplete;
          try {
            final body = jsonDecode(res.body);
            if (body is Map && body.containsKey('data')) {
              final data = body['data'];
              if (data is Map) {
                completedRecordId = (data['_id'] ?? data['id'])?.toString();
                returnedQty = (data['quantity'] ?? returnedQty) as int;
              }
            } else if (body is Map) {
              completedRecordId = (body['_id'] ?? body['id'])?.toString();
              returnedQty = (body['quantity'] ?? returnedQty) as int;
            }
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully completed $returnedQty item${returnedQty > 1 ? 's' : ''} of $productName',
              ),
            ),
          );

          await _fetchOrderFromDatabase();

          _showCompletionRecordedDialog(
            context,
            productId,
            productName,
            returnedQty,
            completedRecordId,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to complete product. Status: ${res.statusCode}',
              ),
            ),
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

  void _showCompletionRecordedDialog(
    BuildContext context,
    String productId,
    String productName,
    int completedQty,
    String? completedRecordId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Completion Recorded'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: $productName'),
            const SizedBox(height: 8),
            Text('Quantity completed: $completedQty'),
            if (completedRecordId != null && completedRecordId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Record ID: $completedRecordId',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelProductByQuantity(
    String productId,
    String productName,
    int quantityToCancel,
  ) async {
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ?? AuthState.currentCustomer?['id'];
      final orderId = _order['_id'] ?? _order['id'];

      if (customerId == null || orderId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to process cancellation')),
          );
        }
        return;
      }

      final uri = backendUri('/api/orders/$orderId/cancel-product');
      final payload = {
        'productId': productId,
        'productName': productName,
        'quantityToCancel': quantityToCancel,
        'customerId': customerId,
        'cancelledAt': DateTime.now().toIso8601String(),
      };

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          // Try to parse returned data from backend so we can show DB-linked confirmation
          String? cancelledRecordId;
          int returnedQty = quantityToCancel;
          try {
            final body = jsonDecode(res.body);
            if (body is Map && body.containsKey('data')) {
              final data = body['data'];
              if (data is Map) {
                cancelledRecordId = (data['_id'] ?? data['id'])?.toString();
                returnedQty = (data['quantity'] ?? returnedQty) as int;
              }
            } else if (body is Map) {
              cancelledRecordId = (body['_id'] ?? body['id'])?.toString();
              returnedQty = (body['quantity'] ?? returnedQty) as int;
            }
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully cancelled $returnedQty item${returnedQty > 1 ? 's' : ''} of $productName',
              ),
            ),
          );
          // Refresh order data
          await _fetchOrderFromDatabase();

          // Show DB-linked cancellation confirmation (no undo option)
          _showCancellationRecordedDialog(
            context,
            productId,
            productName,
            returnedQty,
            cancelledRecordId,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to cancel product. Status: ${res.statusCode}',
              ),
            ),
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

  void _showCancellationRecordedDialog(
    BuildContext context,
    String productId,
    String productName,
    int cancelledQty,
    String? cancelledRecordId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancellation Recorded'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: $productName'),
            const SizedBox(height: 8),
            Text('Quantity cancelled: $cancelledQty'),
            if (cancelledRecordId != null && cancelledRecordId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Record ID: $cancelledRecordId',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Completion-recorded dialog removed (completion flow disabled)

  Future<void> _undoCancelProductByQuantity(
    String productId,
    String productName,
    int quantityToRestore,
  ) async {
    try {
      final customerId =
          AuthState.currentCustomer?['_id'] ?? AuthState.currentCustomer?['id'];
      final orderId = _order['_id'] ?? _order['id'];

      if (customerId == null || orderId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to process undo')),
          );
        }
        return;
      }

      // Attempt to link undo to the DB cancelledProducts entry in the
      // refreshed `_order`. Prefer using the DB record's id and quantity
      // when available so backend can restore the exact cancellation record.
      final cancelledList = (_order['cancelledProducts'] as List?) ?? [];
      Map<String, dynamic>? cancelledRecord;
      for (var i = cancelledList.length - 1; i >= 0; i--) {
        final c = cancelledList[i];
        final prod = c['productId'];
        final pId = prod is Map ? (prod['_id'] ?? '') : (c['productId'] ?? '');
        if (pId == productId) {
          cancelledRecord = c as Map<String, dynamic>?;
          break;
        }
      }

      String? cancelledRecordId;
      int payloadQuantity = quantityToRestore;
      if (cancelledRecord != null) {
        cancelledRecordId = cancelledRecord['_id'] ?? cancelledRecord['id'];
        payloadQuantity =
            (cancelledRecord['quantity'] ?? payloadQuantity) as int;
      }

      final uri = backendUri('/api/orders/$orderId/undo-cancel-product');
      final payload = {
        'productId': productId,
        'productName': productName,
        'quantityToRestore': payloadQuantity,
        'customerId': customerId,
        'restoredAt': DateTime.now().toIso8601String(),
      };
      if (cancelledRecordId != null &&
          cancelledRecordId.toString().isNotEmpty) {
        payload['cancelledRecordId'] = cancelledRecordId;
      }

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully restored $quantityToRestore item${quantityToRestore > 1 ? 's' : ''} of $productName',
              ),
            ),
          );
          // Refresh order data
          await _fetchOrderFromDatabase();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to undo cancellation. Status: ${res.statusCode}',
              ),
            ),
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
}
