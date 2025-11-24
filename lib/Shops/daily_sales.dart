import 'package:flutter/material.dart';

class DailySalesPage extends StatefulWidget {
  const DailySalesPage({super.key});

  @override
  State<DailySalesPage> createState() => _DailySalesPageState();
}

class _DailySalesPageState extends State<DailySalesPage> {
  // Filter state
  bool _showCompletedOnly = false;
  String _selectedPeriod =
      'today'; // 'today', 'all', 'weekly', 'monthly', 'yearly', 'custom'
  DateTime? _startDate;
  DateTime? _endDate;

  // Mock sales data with DateTime
  final List<Map<String, dynamic>> _allSales = [
    {
      'id': 'S1001',
      'date': DateTime(2024, 11, 24, 9, 12),
      'amount': 25.00,
      'status': 'Completed',
      'items': 2,
    },
    {
      'id': 'S1002',
      'date': DateTime(2024, 11, 24, 10, 5),
      'amount': 40.50,
      'status': 'Completed',
      'items': 3,
    },
    {
      'id': 'S1003',
      'date': DateTime(2024, 11, 23, 11, 30),
      'amount': 12.75,
      'status': 'Pending',
      'items': 1,
    },
    {
      'id': 'S1004',
      'date': DateTime(2024, 11, 23, 13, 20),
      'amount': 89.99,
      'status': 'Completed',
      'items': 5,
    },
    {
      'id': 'S1005',
      'date': DateTime(2024, 11, 20, 14, 15),
      'amount': 55.00,
      'status': 'Completed',
      'items': 4,
    },
    {
      'id': 'S1006',
      'date': DateTime(2024, 11, 18, 16, 45),
      'amount': 120.00,
      'status': 'Completed',
      'items': 6,
    },
    {
      'id': 'S1007',
      'date': DateTime(2024, 10, 15, 9, 30),
      'amount': 75.50,
      'status': 'Completed',
      'items': 3,
    },
  ];

  List<Map<String, dynamic>> get _filteredSales {
    List<Map<String, dynamic>> filtered = _allSales;

    // Apply completed filter
    if (_showCompletedOnly) {
      filtered = filtered.where((s) => s['status'] == 'Completed').toList();
    }

    // Apply date range filter based on period
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedPeriod) {
      case 'today':
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        break;
      case 'weekly':
        start = end.subtract(const Duration(days: 7));
        break;
      case 'monthly':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'yearly':
        start = DateTime(now.year, 1, 1);
        break;
      case 'custom':
        if (_startDate != null && _endDate != null) {
          filtered = filtered.where((s) {
            final saleDate = s['date'] as DateTime;
            return saleDate.isAfter(_startDate!) &&
                saleDate.isBefore(_endDate!.add(const Duration(days: 1)));
          }).toList();
        }
        return filtered;
      default:
        return filtered;
    }

    filtered = filtered.where((s) {
      final saleDate = s['date'] as DateTime;
      return saleDate.isAfter(start) && saleDate.isBefore(end);
    }).toList();

    return filtered;
  }

  double get _totalAmount =>
      _filteredSales.fold(0.0, (sum, s) => sum + (s['amount'] as double));

  int get _totalItems =>
      _filteredSales.fold(0, (sum, s) => sum + (s['items'] as int));

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Sales'), elevation: 0),
      body: Column(
        children: [
          // Filter section
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Completed Orders Only'),
                    value: _showCompletedOnly,
                    onChanged: (value) {
                      setState(() {
                        _showCompletedOnly = value ?? false;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  const Text(
                    'Period:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Today'),
                        selected: _selectedPeriod == 'today',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPeriod = 'today';
                              _startDate = null;
                              _endDate = null;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('All Time'),
                        selected: _selectedPeriod == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPeriod = 'all';
                              _startDate = null;
                              _endDate = null;
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
                              _startDate = null;
                              _endDate = null;
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
                              _startDate = null;
                              _endDate = null;
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
                              _startDate = null;
                              _endDate = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Custom Date Range'),
                  ),
                  if (_startDate != null && _endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'From ${_startDate!.toString().split(' ')[0]} to ${_endDate!.toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Summary card
          if (_filteredSales.isNotEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Sales: ${_filteredSales.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Total Amount: \$${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Total Items: $_totalItems',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Sales list
          Expanded(
            child: _filteredSales.isEmpty
                ? Center(
                    child: Text(
                      'No sales found for the selected filters',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filteredSales.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final s = _filteredSales[index];
                      final status = s['status'] as String;
                      final statusColor = status == 'Completed'
                          ? Colors.green
                          : Colors.orange;
                      final saleDate = s['date'] as DateTime;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withOpacity(0.2),
                            child: Icon(
                              status == 'Completed'
                                  ? Icons.check_circle
                                  : Icons.schedule,
                              color: statusColor,
                            ),
                          ),
                          title: Text(
                            '${s['id']} • ${saleDate.hour}:${saleDate.minute.toString().padLeft(2, '0')}',
                          ),
                          subtitle: Text(
                            'Items: ${s['items']} • Status: ${s['status']}',
                          ),
                          trailing: Text(
                            '\$${(s['amount'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Sale ${s['id']}'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date: ${saleDate.toString().split(' ')[0]}',
                                    ),
                                    Text(
                                      'Time: ${saleDate.hour}:${saleDate.minute.toString().padLeft(2, '0')}',
                                    ),
                                    Text('Items: ${s['items']}'),
                                    Text('Status: ${s['status']}'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Amount: \$${(s['amount'] as double).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
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
          ),
        ],
      ),
    );
  }
}
