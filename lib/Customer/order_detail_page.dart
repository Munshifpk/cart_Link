import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme_data.dart';
import '../constant.dart';
import 'product_purchase_page.dart';
import '../services/auth_state.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, List<dynamic>> _productReviews = {};
  bool _loadingReviews = false;

  @override
  void initState() {
    super.initState();
    _fetchAllProductReviews();
  }

  Future<void> _fetchAllProductReviews() async {
    setState(() => _loadingReviews = true);
    final products = (widget.order['products'] as List?) ?? [];
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
      final orderId = widget.order['_id'] ?? widget.order['id'];
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
    final shop = widget.order['shopId'] is Map ? widget.order['shopId'] : null;
    final shopName = shop != null
        ? (shop['shopName'] ?? shop['name'] ?? 'Shop')
        : 'Shop';
    final shopPhone = shop != null
        ? ((shop['contact'] ?? shop['phone'] ?? shop['mobile'] ?? '')
              .toString()
              .trim())
        : '';
    final status = widget.order['orderStatus'] ?? 'pending';
    final date = widget.order['createdAt'] != null
        ? widget.order['createdAt']
              .toString()
              .replaceFirst('T', ' ')
              .split('.')
              .first
        : '';
    final total = (widget.order['totalAmount'] ?? 0).toDouble();
    final products = (widget.order['products'] as List?) ?? [];

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
      body: SingleChildScrollView(
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
              'Order ID: ${widget.order['_id'] ?? ''}',
              style: const TextStyle(color: Colors.black54),
            ),
            Text('Date: $date', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            const Text(
              'Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...products.map<Widget>((p) {
              final prod = p['productId'];
              final name = prod is Map
                  ? (prod['name'] ?? 'Product')
                  : 'Product';
              final productId = prod is Map ? (prod['_id'] ?? '') : '';
              final qty = p['quantity'] ?? 0;
              final price = (p['price'] ?? 0).toDouble();
              final mrp = (p['mrp'] ?? price).toDouble();
              final reviews = _productReviews[productId] ?? [];
              final avgRating = reviews.isNotEmpty
                  ? reviews.fold<double>(
                          0,
                          (sum, r) => sum + ((r['rating'] ?? 0) as num),
                        ) /
                        reviews.length
                  : 0.0;
              return InkWell(
                onTap: productId.isNotEmpty
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductPurchasePage(
                              offer: {'_id': productId, 'name': name},
                            ),
                          ),
                        );
                      }
                    : null,
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Qty: $qty'),
                        if (reviews.isNotEmpty)
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
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if ((mrp - price) > 0)
                          Text(
                            'MRP: ₹${mrp.toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildReviewsSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    // Only show reviews section if order is delivered or completed
    final status = widget.order['orderStatus'] ?? 'pending';
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
}
