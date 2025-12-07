import 'package:flutter/material.dart';
import '../theme_data.dart';

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
      appBar: AppBar(title: const Text('App Updates'),
      foregroundColor: ThemeColors.textColorWhite,
      backgroundColor: ThemeColors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App Updates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Mobile friendly list of updates
              Expanded(
                child: ListView.separated(
                  itemCount: _updates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = _updates[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Text(
                          u['date']!.split('-').first,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      title: Text(
                        u['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(u['desc']!),
                      trailing: Text(
                        u['date']!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
