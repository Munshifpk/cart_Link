import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OfferSalesPage extends StatefulWidget {
  const OfferSalesPage({super.key});

  @override
  State<OfferSalesPage> createState() => _OfferSalesPageState();
}

class _OfferSalesPageState extends State<OfferSalesPage> {
  final List<Map<String, dynamic>> _orders = [
    // sample offer orders (amount is offer price * quantity)
    {
      'orderId': 'OFFER-1001',
      'productId': 1,
      'productName': 'Wireless Headphones',
      'quantity': 1,
      'amount': 1999,
      'date': DateTime.now().subtract(const Duration(days: 0)),
    },
    {
      'orderId': 'OFFER-1002',
      'productId': 2,
      'productName': 'Bluetooth Speaker',
      'quantity': 2,
      'amount': 2700,
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'orderId': 'OFFER-1003',
      'productId': 3,
      'productName': 'Phone Case',
      'quantity': 3,
      'amount': 1047,
      'date': DateTime.now().subtract(const Duration(days: 8)),
    },
    {
      'orderId': 'OFFER-1004',
      'productId': 1,
      'productName': 'Wireless Headphones',
      'quantity': 1,
      'amount': 1999,
      'date': DateTime.now().subtract(const Duration(days: 20)),
    },
    {
      'orderId': 'OFFER-1005',
      'productId': 4,
      'productName': 'Laptop Stand',
      'quantity': 1,
      'amount': 899,
      'date': DateTime.now().subtract(const Duration(days: 40)),
    },
    {
      'orderId': 'OFFER-1006',
      'productId': 2,
      'productName': 'Bluetooth Speaker',
      'quantity': 1,
      'amount': 1350,
      'date': DateTime.now().subtract(const Duration(days: 70)),
    },
    {
      'orderId': 'OFFER-1007',
      'productId': 3,
      'productName': 'Phone Case',
      'quantity': 2,
      'amount': 698,
      'date': DateTime.now().subtract(const Duration(days: 200)),
    },
  ];

  final List<String> _periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  String _selectedPeriod = 'Daily';

  List<String> get _products {
    final p = <String>{'All'};
    for (var o in _orders) {
      p.add(o['productName'] as String);
    }
    return p.toList();
  }

  String _selectedProduct = 'All';

  List<Map<String, dynamic>> get _filteredOrders {
    final now = DateTime.now();
    return _orders.where((o) {
      final DateTime d = o['date'] as DateTime;
      // product filter
      if (_selectedProduct != 'All' && o['productName'] != _selectedProduct)
        return false;

      switch (_selectedPeriod) {
        case 'Daily':
          return d.year == now.year && d.month == now.month && d.day == now.day;
        case 'Weekly':
          return d.isAfter(now.subtract(const Duration(days: 7)));
        case 'Monthly':
          return d.year == now.year && d.month == now.month;
        case 'Yearly':
          return d.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  int get _totalOfferSales {
    return _filteredOrders.fold(0, (s, o) => s + (o['amount'] as int));
  }

  Map<String, int> get _totalsByProduct {
    final map = <String, int>{};
    for (var o in _filteredOrders) {
      final pname = o['productName'] as String;
      map[pname] = (map[pname] ?? 0) + (o['amount'] as int);
    }
    return map;
  }

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer Sales')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: _periods.map((p) {
                      final selected = p == _selectedPeriod;
                      return ChoiceChip(
                        label: Text(p),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedPeriod = p;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedProduct,
                  items: _products
                      .map(
                        (prod) =>
                            DropdownMenuItem(value: prod, child: Text(prod)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedProduct = v;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Totals
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Offer Sales',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${_totalOfferSales}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Orders',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_filteredOrders.length}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Product-wise totals
            if (_totalsByProduct.isNotEmpty)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sales by Product',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._totalsByProduct.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key),
                              Text(
                                '₹${e.value}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            const Text('Orders', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredOrders.isEmpty
                  ? const Center(
                      child: Text('No offer sales for selected period/product'),
                    )
                  : ListView.separated(
                      itemCount: _filteredOrders.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final o = _filteredOrders[index];
                        return ListTile(
                          title: Text(o['productName'] as String),
                          subtitle: Text(
                            '${o['orderId']} • ${_formatDate(o['date'] as DateTime)}',
                          ),
                          trailing: Text(
                            '₹${o['amount']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
