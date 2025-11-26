import 'package:flutter/material.dart';

class ConfirmedOrdersPage extends StatefulWidget {
  const ConfirmedOrdersPage({super.key});

  @override
  State<ConfirmedOrdersPage> createState() => _ConfirmedOrdersPageState();
}

class _ConfirmedOrdersPageState extends State<ConfirmedOrdersPage> {
  String _selectedPeriod = 'daily';

  final Map<String, List<Map<String, dynamic>>> _confirmedOrdersData = {
    'daily': [
      {
        'orderId': 'ORD001',
        'customerName': 'John Doe',
        'date': 'Nov 24, 9:15 AM',
        'amount': 2500,
        'items': 5,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD002',
        'customerName': 'Jane Smith',
        'date': 'Nov 24, 10:30 AM',
        'amount': 1850,
        'items': 3,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD003',
        'customerName': 'Mike Johnson',
        'date': 'Nov 24, 11:45 AM',
        'amount': 3200,
        'items': 7,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD004',
        'customerName': 'Sarah Williams',
        'date': 'Nov 24, 1:20 PM',
        'amount': 2100,
        'items': 4,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD005',
        'customerName': 'Tom Brown',
        'date': 'Nov 24, 2:50 PM',
        'amount': 1500,
        'items': 2,
        'status': 'Confirmed',
      },
    ],
    'weekly': [
      {
        'orderId': 'ORD051',
        'customerName': 'Alice Johnson',
        'date': 'Nov 18',
        'amount': 12500,
        'items': 28,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD052',
        'customerName': 'Bob Smith',
        'date': 'Nov 19',
        'amount': 14200,
        'items': 32,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD053',
        'customerName': 'Charlie Davis',
        'date': 'Nov 20',
        'amount': 15800,
        'items': 35,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD054',
        'customerName': 'Diana Evans',
        'date': 'Nov 21',
        'amount': 13900,
        'items': 30,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD055',
        'customerName': 'Eve Martinez',
        'date': 'Nov 22',
        'amount': 16500,
        'items': 37,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD056',
        'customerName': 'Frank Garcia',
        'date': 'Nov 23',
        'amount': 17800,
        'items': 40,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD057',
        'customerName': 'Grace Lee',
        'date': 'Nov 24',
        'amount': 17300,
        'items': 38,
        'status': 'Confirmed',
      },
    ],
    'monthly': [
      {
        'orderId': 'ORD100',
        'customerName': 'Week 1 Total',
        'date': 'Week 1',
        'amount': 78000,
        'items': 156,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD101',
        'customerName': 'Week 2 Total',
        'date': 'Week 2',
        'amount': 82500,
        'items': 168,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD102',
        'customerName': 'Week 3 Total',
        'date': 'Week 3',
        'amount': 76200,
        'items': 152,
        'status': 'Confirmed',
      },
      {
        'orderId': 'ORD103',
        'customerName': 'Week 4 Total',
        'date': 'Week 4',
        'amount': 89800,
        'items': 180,
        'status': 'Confirmed',
      },
    ],
    'yearly': [
      {
        'orderId': 'JAN2024',
        'customerName': 'January',
        'date': 'Jan 2024',
        'amount': 625000,
        'items': 1420,
        'status': 'Confirmed',
      },
      {
        'orderId': 'FEB2024',
        'customerName': 'February',
        'date': 'Feb 2024',
        'amount': 685000,
        'items': 1560,
        'status': 'Confirmed',
      },
      {
        'orderId': 'MAR2024',
        'customerName': 'March',
        'date': 'Mar 2024',
        'amount': 745000,
        'items': 1680,
        'status': 'Confirmed',
      },
      {
        'orderId': 'APR2024',
        'customerName': 'April',
        'date': 'Apr 2024',
        'amount': 815000,
        'items': 1850,
        'status': 'Confirmed',
      },
      {
        'orderId': 'MAY2024',
        'customerName': 'May',
        'date': 'May 2024',
        'amount': 765000,
        'items': 1740,
        'status': 'Confirmed',
      },
      {
        'orderId': 'JUN2024',
        'customerName': 'June',
        'date': 'Jun 2024',
        'amount': 845000,
        'items': 1920,
        'status': 'Confirmed',
      },
      {
        'orderId': 'JUL2024',
        'customerName': 'July',
        'date': 'Jul 2024',
        'amount': 895000,
        'items': 2035,
        'status': 'Confirmed',
      },
      {
        'orderId': 'AUG2024',
        'customerName': 'August',
        'date': 'Aug 2024',
        'amount': 825000,
        'items': 1875,
        'status': 'Confirmed',
      },
      {
        'orderId': 'SEP2024',
        'customerName': 'September',
        'date': 'Sep 2024',
        'amount': 745000,
        'items': 1690,
        'status': 'Confirmed',
      },
      {
        'orderId': 'OCT2024',
        'customerName': 'October',
        'date': 'Oct 2024',
        'amount': 925000,
        'items': 2100,
        'status': 'Confirmed',
      },
      {
        'orderId': 'NOV2024',
        'customerName': 'November',
        'date': 'Nov 2024',
        'amount': 850000,
        'items': 1930,
        'status': 'Confirmed',
      },
      {
        'orderId': 'DEC2024',
        'customerName': 'December',
        'date': 'Dec 2024',
        'amount': 1000000,
        'items': 2275,
        'status': 'Confirmed',
      },
    ],
  };

  List<Map<String, dynamic>> get _currentData =>
      _confirmedOrdersData[_selectedPeriod] ?? [];

  int get _totalOrders => _currentData.length;

  int get _totalAmount =>
      _currentData.fold(0, (sum, item) => sum + (item['amount'] as int));

  int get _totalItems =>
      _currentData.fold(0, (sum, item) => sum + (item['items'] as int));

  double get _averageAmount =>
      _totalOrders > 0 ? _totalAmount / _totalOrders : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmed Orders'), elevation: 0),
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
                  title: 'Total Completed',
                  value: _totalOrders.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
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
              'Completed Orders Details',
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
                      backgroundColor: Colors.green.withOpacity(0.2),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
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
                          'Items: ${order['items']} • ${order['date']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '₹${order['amount']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Order ${order['orderId']}'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer: ${order['customerName']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Date: ${order['date']}'),
                                const SizedBox(height: 8),
                                Text('Items: ${order['items']}'),
                                const SizedBox(height: 8),
                                Text('Amount: ₹${order['amount']}'),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    order['status'],
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
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
}
