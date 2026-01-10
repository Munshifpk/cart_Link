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
      appBar: AppBar(
        title: const Text('App Updates'),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Mobile friendly list of updates
              Expanded(
                child: ListView.separated(
                  itemCount: _updates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final u = _updates[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ThemeColors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                ThemeColors.primary.withOpacity(0.12),
                            child: Text(
                              u['date']!.split('-').first,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ThemeColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u['title']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ThemeColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  u['desc']!,
                                  style: const TextStyle(
                                    color: ThemeColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            u['date']!,
                            style: const TextStyle(
                              color: ThemeColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
