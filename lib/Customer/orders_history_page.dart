import 'package:flutter/material.dart';

class OrdersHistoryPage extends StatelessWidget {
  const OrdersHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock order history data
    final orders = [
      {
        'id': 'ORD-2024-001',
        'date': '2024-11-20',
        'shop': 'Hilite Store',
        'total': 85.50,
        'status': 'Delivered',
        'items': 3,
      },
      {
        'id': 'ORD-2024-002',
        'date': '2024-11-18',
        'shop': 'Lulu Market',
        'total': 120.00,
        'status': 'Delivered',
        'items': 5,
      },
      {
        'id': 'ORD-2024-003',
        'date': '2024-11-15',
        'shop': 'Yara Shop',
        'total': 45.75,
        'status': 'Processing',
        'items': 2,
      },
      {
        'id': 'ORD-2024-004',
        'date': '2024-11-12',
        'shop': 'Mattile Store',
        'total': 200.00,
        'status': 'Cancelled',
        'items': 8,
      },
      {
        'id': 'ORD-2024-005',
        'date': '2024-11-10',
        'shop': 'ExampleShop',
        'total': 65.25,
        'status': 'Delivered',
        'items': 4,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final order = orders[index];
          final status = order['status'] as String;
          final statusColor = status == 'Delivered'
              ? Colors.green
              : status == 'Processing'
              ? Colors.orange
              : Colors.red;

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.2),
                child: Icon(
                  status == 'Delivered'
                      ? Icons.check_circle
                      : status == 'Processing'
                      ? Icons.schedule
                      : Icons.cancel,
                  color: statusColor,
                ),
              ),
              title: Text('${order['id']} • ${order['shop']}'),
              subtitle: Text(
                'Date: ${order['date']} • Items: ${order['items']}',
              ),
              trailing: Text(
                '\$${(order['total'] as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Order ${order['id']}'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shop: ${order['shop']}'),
                        Text('Date: ${order['date']}'),
                        Text('Items: ${order['items']}'),
                        Text('Status: ${order['status']}'),
                        const SizedBox(height: 8),
                        Text(
                          'Total: \$${(order['total'] as double).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
