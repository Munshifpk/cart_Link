import 'package:flutter/material.dart';

class CancelledOrdersPage extends StatefulWidget {
  const CancelledOrdersPage({super.key});

  @override
  State<CancelledOrdersPage> createState() => _CancelledOrdersPageState();
}

class _CancelledOrdersPageState extends State<CancelledOrdersPage> {
  String _selectedPeriod = 'daily';

  final Map<String, List<Map<String, dynamic>>> _cancelledOrdersData = {
    'daily': [
      {
        'orderId': 'ORD101',
        'customerName': 'Alex Rivera',
        'customerEmail': 'alex@email.com',
        'customerPhone': '+91 9876543210',
        'date': 'Nov 24, 8:45 AM',
        'amount': 1200,
        'items': 3,
        'status': 'Cancelled',
        'reason': 'Product out of stock',
        'feedback': 'Better inventory management needed',
        'products': [
          {'name': 'Wireless Headphones', 'quantity': 1, 'price': 500},
          {'name': 'Phone Case', 'quantity': 2, 'price': 350},
        ],
      },
      {
        'orderId': 'ORD102',
        'customerName': 'Lisa Chen',
        'customerEmail': 'lisa.chen@email.com',
        'customerPhone': '+91 8765432109',
        'date': 'Nov 24, 10:20 AM',
        'amount': 2150,
        'items': 5,
        'status': 'Cancelled',
        'reason': 'Customer requested cancellation',
        'feedback': 'Found better prices elsewhere',
        'products': [
          {'name': 'USB Cable', 'quantity': 2, 'price': 300},
          {'name': 'Screen Protector', 'quantity': 3, 'price': 650},
        ],
      },
      {
        'orderId': 'ORD103',
        'customerName': 'Marcus Thompson',
        'customerEmail': 'marcus.t@email.com',
        'customerPhone': '+91 7654321098',
        'date': 'Nov 24, 12:30 PM',
        'amount': 890,
        'items': 2,
        'status': 'Cancelled',
        'reason': 'Delivery address issue',
        'feedback': 'Address verification process was confusing',
        'products': [
          {'name': 'Phone Charger', 'quantity': 1, 'price': 450},
          {'name': 'Tempered Glass', 'quantity': 1, 'price': 440},
        ],
      },
      {
        'orderId': 'ORD104',
        'customerName': 'Emma Watson',
        'customerEmail': 'emma.w@email.com',
        'customerPhone': '+91 6543210987',
        'date': 'Nov 24, 2:15 PM',
        'amount': 3450,
        'items': 8,
        'status': 'Cancelled',
        'reason': 'Payment failed',
        'feedback': 'Payment gateway issues, will retry later',
        'products': [
          {'name': 'Bluetooth Speaker', 'quantity': 1, 'price': 1200},
          {'name': 'Phone Stand', 'quantity': 2, 'price': 600},
          {'name': 'Cable Organizer', 'quantity': 5, 'price': 850},
        ],
      },
      {
        'orderId': 'ORD105',
        'customerName': 'David Kumar',
        'customerEmail': 'david.k@email.com',
        'customerPhone': '+91 5432109876',
        'date': 'Nov 24, 3:45 PM',
        'amount': 1650,
        'items': 4,
        'status': 'Cancelled',
        'reason': 'Duplicate order',
        'feedback': 'Accidentally placed the same order twice',
        'products': [
          {'name': 'Laptop Stand', 'quantity': 1, 'price': 800},
          {'name': 'Keyboard', 'quantity': 1, 'price': 850},
        ],
      },
    ],
    'weekly': [
      {
        'orderId': 'ORD201',
        'customerName': 'Nina Patel',
        'customerEmail': 'nina.p@email.com',
        'customerPhone': '+91 4321098765',
        'date': 'Nov 18',
        'amount': 8900,
        'items': 22,
        'status': 'Cancelled',
        'reason': 'Product out of stock',
        'feedback': 'Need better stock information',
      },
      {
        'orderId': 'ORD202',
        'customerName': 'Omar Hassan',
        'customerEmail': 'omar.h@email.com',
        'customerPhone': '+91 3210987654',
        'date': 'Nov 19',
        'amount': 9200,
        'items': 24,
        'status': 'Cancelled',
        'reason': 'Customer requested cancellation',
        'feedback': 'Shipping cost was too high',
      },
      {
        'orderId': 'ORD203',
        'customerName': 'Rachel Green',
        'customerEmail': 'rachel.g@email.com',
        'customerPhone': '+91 2109876543',
        'date': 'Nov 20',
        'amount': 7650,
        'items': 18,
        'status': 'Cancelled',
        'reason': 'Delivery address issue',
        'feedback': 'Delivery location not clear',
      },
      {
        'orderId': 'ORD204',
        'customerName': 'Samuel Bell',
        'customerEmail': 'samuel.b@email.com',
        'customerPhone': '+91 1098765432',
        'date': 'Nov 21',
        'amount': 10200,
        'items': 26,
        'status': 'Cancelled',
        'reason': 'Payment failed',
        'feedback': 'Card declined, network issue',
      },
      {
        'orderId': 'ORD205',
        'customerName': 'Victoria Stone',
        'customerEmail': 'victoria.s@email.com',
        'customerPhone': '+91 9999999999',
        'date': 'Nov 22',
        'amount': 8500,
        'items': 20,
        'status': 'Cancelled',
        'reason': 'Duplicate order',
        'feedback': 'Accidental duplicate, need cancel option',
      },
      {
        'orderId': 'ORD206',
        'customerName': 'William Scott',
        'customerEmail': 'william.s@email.com',
        'customerPhone': '+91 9888888888',
        'date': 'Nov 23',
        'amount': 9100,
        'items': 23,
        'status': 'Cancelled',
        'reason': 'Product out of stock',
        'feedback': 'Wish list feature would help',
      },
      {
        'orderId': 'ORD207',
        'customerName': 'Zara Knight',
        'customerEmail': 'zara.k@email.com',
        'customerPhone': '+91 9777777777',
        'date': 'Nov 24',
        'amount': 8700,
        'items': 21,
        'status': 'Cancelled',
        'reason': 'Customer requested cancellation',
        'feedback': 'Great service, just changed mind',
      },
    ],
    'monthly': [
      {
        'orderId': 'MON101',
        'customerName': 'Week 1 Total',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Week 1',
        'amount': 45000,
        'items': 120,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'MON102',
        'customerName': 'Week 2 Total',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Week 2',
        'amount': 48500,
        'items': 128,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'MON103',
        'customerName': 'Week 3 Total',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Week 3',
        'amount': 42800,
        'items': 112,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'MON104',
        'customerName': 'Week 4 Total',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Week 4',
        'amount': 51200,
        'items': 135,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
    ],
    'yearly': [
      {
        'orderId': 'JAN2024',
        'customerName': 'January',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Jan 2024',
        'amount': 325000,
        'items': 840,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'FEB2024',
        'customerName': 'February',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Feb 2024',
        'amount': 365000,
        'items': 920,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'MAR2024',
        'customerName': 'March',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Mar 2024',
        'amount': 385000,
        'items': 1020,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'APR2024',
        'customerName': 'April',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Apr 2024',
        'amount': 405000,
        'items': 1100,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'MAY2024',
        'customerName': 'May',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'May 2024',
        'amount': 375000,
        'items': 980,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'JUN2024',
        'customerName': 'June',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Jun 2024',
        'amount': 415000,
        'items': 1080,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'JUL2024',
        'customerName': 'July',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Jul 2024',
        'amount': 445000,
        'items': 1160,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'AUG2024',
        'customerName': 'August',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Aug 2024',
        'amount': 405000,
        'items': 1050,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'SEP2024',
        'customerName': 'September',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Sep 2024',
        'amount': 375000,
        'items': 975,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'OCT2024',
        'customerName': 'October',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Oct 2024',
        'amount': 465000,
        'items': 1210,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'NOV2024',
        'customerName': 'November',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Nov 2024',
        'amount': 425000,
        'items': 1100,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
      {
        'orderId': 'DEC2024',
        'customerName': 'December',
        'customerEmail': 'N/A',
        'customerPhone': 'N/A',
        'date': 'Dec 2024',
        'amount': 510000,
        'items': 1325,
        'status': 'Cancelled',
        'reason': 'Multiple reasons',
        'feedback': 'Varies by customer',
      },
    ],
  };

  List<Map<String, dynamic>> get _currentData =>
      _cancelledOrdersData[_selectedPeriod] ?? [];

  int get _totalOrders => _currentData.length;

  int get _totalAmount =>
      _currentData.fold(0, (sum, item) => sum + _toInt(item['amount']));

  int get _totalItems =>
      _currentData.fold(0, (sum, item) => sum + _toInt(item['items']));

  double get _averageAmount =>
      _totalOrders > 0 ? _totalAmount / _totalOrders : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cancelled Orders'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Period:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Daily'),
                  selected: _selectedPeriod == 'daily',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriod = 'daily';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Weekly'),
                  selected: _selectedPeriod == 'weekly',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriod = 'weekly';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Monthly'),
                  selected: _selectedPeriod == 'monthly',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriod = 'monthly';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Yearly'),
                  selected: _selectedPeriod == 'yearly',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriod = 'yearly';
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildSummaryCard(
                  title: 'Total Cancelled',
                  value: _totalOrders.toString(),
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
                _buildSummaryCard(
                  title: 'Total Amount',
                  value: '₹$_totalAmount',
                  icon: Icons.currency_rupee,
                  color: Colors.blue,
                ),
                _buildSummaryCard(
                  title: 'Total Items',
                  value: _totalItems.toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.orange,
                ),
                _buildSummaryCard(
                  title: 'Average Amount',
                  value: '₹${_averageAmount.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Cancelled Orders Details',
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
                      backgroundColor: Colors.red.withOpacity(0.2),
                      child: const Icon(Icons.cancel, color: Colors.red),
                    ),
                    title: Text(
                      order['orderId'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${order['customerName']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Reason: ${order['reason']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '₹${_toString(order['amount'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      _showCancelledOrderDetails(context, order);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showCancelledOrderDetails(
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildDetailField('Name', _toString(order['customerName'])),
              _buildDetailField('Email', _toString(order['customerEmail'])),
              _buildDetailField('Phone', _toString(order['customerPhone'])),
              const SizedBox(height: 16),
              const Text(
                'Order Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildDetailField('Date', _toString(order['date'])),
              _buildDetailField('Items', _toString(order['items'])),
              _buildDetailField('Amount', '₹${_toString(order['amount'])}'),
              const SizedBox(height: 16),
              const Text(
                'Cancellation Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildDetailField('Reason', _toString(order['reason'])),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _toString(order['feedback']),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
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

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 20,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _toString(dynamic v) {
    if (v == null) return 'N/A';
    return v.toString();
  }
}
