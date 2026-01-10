import 'package:flutter/material.dart';
import 'package:cart_link/theme_data.dart';

class PendingOrdersPage extends StatefulWidget {
  const PendingOrdersPage({super.key});

  @override
  State<PendingOrdersPage> createState() => _PendingOrdersPageState();
}

class _PendingOrdersPageState extends State<PendingOrdersPage> {
  String _selectedPeriod = 'daily';

  final Map<String, List<Map<String, dynamic>>> _pendingOrdersData = {
    'daily': [
      {
        'orderId': 'PEND101',
        'customerName': 'Aisha Khan',
        'customerEmail': 'aisha.k@example.com',
        'customerPhone': '+91 9123456780',
        'date': 'Nov 24, 11:10 AM',
        'amount': 950,
        'items': 2,
        'status': 'Pending',
        'note': 'Awaiting payment confirmation',
        'feedback': 'N/A',
      },
      {
        'orderId': 'PEND102',
        'customerName': 'Rohan Das',
        'customerEmail': 'rohan.d@example.com',
        'customerPhone': '+91 9988776655',
        'date': 'Nov 24, 12:05 PM',
        'amount': 2400,
        'items': 4,
        'status': 'Pending',
        'note': 'Payment failed previously, retrying',
        'feedback': 'Please support retry',
      },
    ],
    'weekly': [],
    'monthly': [],
    'yearly': [],
  };

  List<Map<String, dynamic>> get _currentData =>
      _pendingOrdersData[_selectedPeriod] ?? [];

  String _toString(dynamic v) {
    if (v == null) return 'N/A';
    return v.toString();
  }

  void _showPendingOrderDetails(
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
                'Status & Notes',
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
      appBar: AppBar(title: const Text('Pending Orders')),
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
              'Pending Orders Details',
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
                      backgroundColor: ThemeColors.warning.withOpacity(0.2),
                      child: const Icon(Icons.schedule, color: ThemeColors.warning),
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
                        color: ThemeColors.warning,
                      ),
                    ),
                    onTap: () => _showPendingOrderDetails(context, order),
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
