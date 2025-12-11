import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme_data.dart';
import 'product_purchase_page.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

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
              const Text('Phone Number:', style: TextStyle(fontWeight: FontWeight.w600)),
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
    final shop = order['shopId'] is Map ? order['shopId'] : null;
    final shopName = shop != null ? (shop['shopName'] ?? shop['name'] ?? 'Shop') : 'Shop';
    final shopPhone = shop != null 
        ? ((shop['contact'] ?? shop['phone'] ?? shop['mobile'] ?? '').toString().trim())
        : '';
    final status = order['orderStatus'] ?? 'pending';
    final date = order['createdAt'] != null
        ? order['createdAt'].toString().replaceFirst('T', ' ').split('.').first
        : '';
    final total = (order['totalAmount'] ?? 0).toDouble();
    final products = (order['products'] as List?) ?? [];

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
                      Text(shopName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (shopPhone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('Phone: $shopPhone', style: const TextStyle(color: Colors.black54)),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Order ID: ${order['_id'] ?? ''}', style: const TextStyle(color: Colors.black54)),
            Text('Date: $date', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: shopPhone.isNotEmpty ? () => _contactShopWhatsApp(shopPhone) : null,
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shopPhone.isNotEmpty ? const Color(0xFF25D366) : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: shopPhone.isNotEmpty ? () => _showCallDialog(context, shopPhone) : null,
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shopPhone.isNotEmpty ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...products.map<Widget>((p) {
              final prod = p['productId'];
              final name = prod is Map ? (prod['name'] ?? 'Product') : 'Product';
              final productId = prod is Map ? (prod['_id'] ?? '') : '';
              final qty = p['quantity'] ?? 0;
              final price = (p['price'] ?? 0).toDouble();
              final mrp = (p['mrp'] ?? price).toDouble();
              return InkWell(
                onTap: productId.isNotEmpty ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductPurchasePage(offer: {'_id': productId, 'name': name}),
                    ),
                  );
                } : null,
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Qty: $qty'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if ((mrp - price) > 0)
                          Text('MRP: ₹${mrp.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black45, fontSize: 12)),
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
                const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
