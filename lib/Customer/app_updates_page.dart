import 'package:flutter/material.dart';

class AppUpdatesPage extends StatefulWidget {
  const AppUpdatesPage({super.key});

  @override
  State<AppUpdatesPage> createState() => _AppUpdatesPageState();
}

class _AppUpdatesPageState extends State<AppUpdatesPage> {
  final List<Map<String, String>> _updates = [
    {
      'title': 'Version 1.2.0',
      'desc': 'Improved offer management and bug fixes',
      'date': '2025-11-20',
    },
    {
      'title': 'Maintenance Notice',
      'desc': 'Scheduled maintenance on 2025-12-01',
      'date': '2025-11-18',
    },
    {
      'title': 'Hotfix 1.2.1',
      'desc': 'Fix crash when opening offers page',
      'date': '2025-11-24',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Updates')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Updates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Data table showing updates in tabular form
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Description')),
                ],
                rows: List.generate(_updates.length, (i) {
                  final u = _updates[i];
                  return DataRow(
                    cells: [
                      DataCell(Text(u['date']!)),
                      DataCell(Text(u['title']!)),
                      DataCell(Text(u['desc']!)),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
