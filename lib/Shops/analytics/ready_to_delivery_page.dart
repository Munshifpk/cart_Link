import 'package:flutter/material.dart';

class ReadyToDeliveryPage extends StatefulWidget {
  const ReadyToDeliveryPage({super.key});

  @override
  State<ReadyToDeliveryPage> createState() => _ReadyToDeliveryPageState();
}

class _ReadyToDeliveryPageState extends State<ReadyToDeliveryPage> {
  String _selectedPeriod = 'daily';

  final Map<String, List<Map<String, dynamic>>> _readyOrdersData = {
    'daily': [
      {
        'orderId': 'RD101',
        'customerName': 'Sana Ali',
        'customerEmail': 'sana.ali@example.com',
        'customerPhone': '+91 9012345678',
        'date': 'Nov 24, 3:05 PM',
        'amount': 2750,
        'items': 6,
        'status': 'Ready to Deliver',
        'note': 'Packed and ready at dispatch center',
        'feedback': 'Please deliver between 5-8 PM',
      },
      {
        'orderId': 'RD102',
        'customerName': 'Vikram Singh',
        'customerEmail': 'vikram.s@example.com',
        'customerPhone': '+91 9876501234',
        'date': 'Nov 24, 1:30 PM',
        'amount': 1299,
        'items': 1,
        'status': 'Ready to Deliver',
        'note': 'Rider assigned',
        'feedback': 'Fragile item, handle carefully',
      },
    ],
    'weekly': [],
    'monthly': [],
    'yearly': [],
  };

  List<Map<String, dynamic>> get _currentData =>
      _readyOrdersData[_selectedPeriod] ?? [];

  String _toString(dynamic v) => v == null ? 'N/A' : v.toString();

  void _showReadyOrderDetails(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order ${order['orderId']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Name: ${_toString(order['customerName'])}'),
              Text('Email: ${_toString(order['customerEmail'])}'),
              Text('Phone: ${_toString(order['customerPhone'])}'),
              const SizedBox(height: 12),
              const Text(
                'Order Info',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Date: ${_toString(order['date'])}'),
              Text('Items: ${_toString(order['items'])}'),
              Text('Amount: ₹${_toString(order['amount'])}'),
              const SizedBox(height: 12),
              const Text(
                'Delivery Status & Notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Status: ${_toString(order['status'])}'),
              Text('Note: ${_toString(order['note'])}'),
              const SizedBox(height: 12),
              const Text(
                'Customer Feedback',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_toString(order['feedback'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ready to Deliver Orders')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Period:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Daily'),
                  selected: _selectedPeriod == 'daily',
                  onSelected: (s) {
                    if (s) setState(() => _selectedPeriod = 'daily');
                  },
                ),
                ChoiceChip(
                  label: const Text('Weekly'),
                  selected: _selectedPeriod == 'weekly',
                  onSelected: (s) {
                    if (s) setState(() => _selectedPeriod = 'weekly');
                  },
                ),
                ChoiceChip(
                  label: const Text('Monthly'),
                  selected: _selectedPeriod == 'monthly',
                  onSelected: (s) {
                    if (s) setState(() => _selectedPeriod = 'monthly');
                  },
                ),
                ChoiceChip(
                  label: const Text('Yearly'),
                  selected: _selectedPeriod == 'yearly',
                  onSelected: (s) {
                    if (s) setState(() => _selectedPeriod = 'yearly');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Orders Ready for Delivery',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentData.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final order = _currentData[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.2),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.teal,
                      ),
                    ),
                    title: Text(
                      order['orderId'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Customer: ${_toString(order['customerName'])}\n${_toString(order['date'])}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      '₹${_toString(order['amount'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    onTap: () => _showReadyOrderDetails(context, order),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
