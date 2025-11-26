import 'package:flutter/material.dart';

class OrdersAnalyticsPage extends StatefulWidget {
  const OrdersAnalyticsPage({super.key});

  @override
  State<OrdersAnalyticsPage> createState() => _OrdersAnalyticsPageState();
}

class _OrdersAnalyticsPageState extends State<OrdersAnalyticsPage> {
  String _selectedPeriod = 'daily'; // 'daily', 'weekly', 'monthly', 'yearly'

  // Mock order data
  final Map<String, List<Map<String, dynamic>>> _orderData = {
    'daily': [
      {'date': 'Nov 24, 9 AM', 'orders': 5, 'amount': 1250},
      {'date': 'Nov 24, 10 AM', 'orders': 8, 'amount': 2100},
      {'date': 'Nov 24, 11 AM', 'orders': 12, 'amount': 3200},
      {'date': 'Nov 24, 12 PM', 'orders': 6, 'amount': 1800},
      {'date': 'Nov 24, 1 PM', 'orders': 10, 'amount': 2650},
      {'date': 'Nov 24, 2 PM', 'orders': 9, 'amount': 2400},
      {'date': 'Nov 24, 3 PM', 'orders': 7, 'amount': 1950},
      {'date': 'Nov 24, 4 PM', 'orders': 11, 'amount': 2950},
    ],
    'weekly': [
      {'date': 'Nov 18', 'orders': 45, 'amount': 12500},
      {'date': 'Nov 19', 'orders': 52, 'amount': 14200},
      {'date': 'Nov 20', 'orders': 61, 'amount': 16800},
      {'date': 'Nov 21', 'orders': 58, 'amount': 15900},
      {'date': 'Nov 22', 'orders': 67, 'amount': 18500},
      {'date': 'Nov 23', 'orders': 71, 'amount': 19600},
      {'date': 'Nov 24', 'orders': 68, 'amount': 18900},
    ],
    'monthly': [
      {'date': 'Week 1', 'orders': 280, 'amount': 78000},
      {'date': 'Week 2', 'orders': 310, 'amount': 86500},
      {'date': 'Week 3', 'orders': 295, 'amount': 82100},
      {'date': 'Week 4', 'orders': 340, 'amount': 94800},
    ],
    'yearly': [
      {'date': 'January', 'orders': 2450, 'amount': 680000},
      {'date': 'February', 'orders': 2680, 'amount': 745000},
      {'date': 'March', 'orders': 2890, 'amount': 805000},
      {'date': 'April', 'orders': 3120, 'amount': 870000},
      {'date': 'May', 'orders': 2950, 'amount': 820000},
      {'date': 'June', 'orders': 3280, 'amount': 915000},
      {'date': 'July', 'orders': 3450, 'amount': 960000},
      {'date': 'August', 'orders': 3180, 'amount': 885000},
      {'date': 'September', 'orders': 2890, 'amount': 805000},
      {'date': 'October', 'orders': 3560, 'amount': 990000},
      {'date': 'November', 'orders': 3240, 'amount': 900000},
      {'date': 'December', 'orders': 3890, 'amount': 1080000},
    ],
  };

  List<Map<String, dynamic>> get _currentData =>
      _orderData[_selectedPeriod] ?? [];

  int get _totalOrders =>
      _currentData.fold(0, (sum, item) => sum + (item['orders'] as int));

  int get _totalAmount =>
      _currentData.fold(0, (sum, item) => sum + (item['amount'] as int));

  double get _averageOrders => _totalOrders / _currentData.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders Analytics'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector chips
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

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Orders',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _totalOrders.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹$_totalAmount',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Average Orders',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _averageOrders.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.trending_up, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detailed List
            const Text(
              'Detailed View',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentData.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = _currentData[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  title: Text(item['date']),
                  subtitle: Text('Orders: ${item['orders']}'),
                  trailing: Text(
                    '₹${item['amount']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
}
