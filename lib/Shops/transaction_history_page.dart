import 'package:flutter/material.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock transaction data
    final transactions = [
      {'id': 'T1001', 'time': '09:12', 'amount': 25.00, 'status': 'Completed'},
      {'id': 'T1002', 'time': '10:05', 'amount': 40.50, 'status': 'Completed'},
      {'id': 'T1003', 'time': '11:30', 'amount': 12.75, 'status': 'Refunded'},
      {'id': 'T1004', 'time': '13:20', 'amount': 89.99, 'status': 'Completed'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final t = transactions[i];
          return ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text('${t['id']}  •  ${t['time']}'),
            subtitle: Text('Status: ${t['status']}'),
            trailing: Text(
              '\$${(t['amount'] as double).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Transaction ${t['id']}'),
                  content: Text(
                    'Amount: \$${(t['amount'] as double).toStringAsFixed(2)}\nStatus: ${t['status']}\nTime: ${t['time']}',
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
          );
        },
      ),
    );
  }
}
