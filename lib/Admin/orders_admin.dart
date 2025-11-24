import 'package:flutter/material.dart';
import '../theme_data.dart';

class OrdersAdmin extends StatefulWidget {
  const OrdersAdmin({super.key});

  @override
  State<OrdersAdmin> createState() => _OrdersAdminState();
}

class Order {
  final String id;
  final String customerName;
  final String details;
  final double total;
  String status;

  Order({
    required this.id,
    required this.customerName,
    required this.details,
    required this.total,
    required this.status,
  });
}

class _OrdersAdminState extends State<OrdersAdmin> {
  final List<Order> _orders = [
    Order(
      id: 'ORD-1001',
      customerName: 'Asha Patel',
      details: '2x Apples, 1x Milk',
      total: 12.50,
      status: 'Pending',
    ),
    Order(
      id: 'ORD-1002',
      customerName: 'Rahul Kumar',
      details: '1x Laptop Charger',
      total: 599.99,
      status: 'Processing',
    ),
    Order(
      id: 'ORD-1003',
      customerName: 'Meera Singh',
      details: '3x T-shirts',
      total: 45.00,
      status: 'Shipped',
    ),
    Order(
      id: 'ORD-1004',
      customerName: 'Karan Rao',
      details: '5x Bananas, 1x Bread',
      total: 8.75,
      status: 'Delivered',
    ),
    Order(
      id: 'ORD-1005',
      customerName: 'Lina George',
      details: '1x Phone Case',
      total: 9.99,
      status: 'Cancelled',
    ),
  ];

  // Statuses are displayed read-only in the table.

  void _showOrderDetails(Order order) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order ${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.customerName}'),
            const SizedBox(height: 8),
            Text('Items: ${order.details}'),
            const SizedBox(height: 8),
            Text('Total: ₹${order.total.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Status: ${order.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: ThemeColors.primary,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => ThemeColors.primary,
                ),
                headingRowHeight: 56,
                dataRowMinHeight: 70,
                dataRowMaxHeight: 70,
                columnSpacing: 20,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Order ID',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Customer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                rows: List.generate(_orders.length, (index) {
                  final o = _orders[index];
                  return DataRow(
                    cells: [
                      DataCell(Text(o.id)),
                      DataCell(Text(o.customerName)),
                      DataCell(Text(o.details)),
                      DataCell(Text('₹${o.total.toStringAsFixed(2)}')),
                      DataCell(Text(o.status)),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'Details',
                          onPressed: () => _showOrderDetails(o),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
