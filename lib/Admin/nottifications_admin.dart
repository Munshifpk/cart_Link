import 'package:flutter/material.dart';
import '../theme_data.dart';

class NotificationsAdmin extends StatefulWidget {
  const NotificationsAdmin({super.key});

  @override
  State<NotificationsAdmin> createState() => _NotificationsAdminState();
}

class _NotificationsAdminState extends State<NotificationsAdmin> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.new_releases,
      'title': 'New Shop Registration',
      'subtitle': 'A new shop "Green Grocers" has registered.',
      'time': '10 min ago',
      'isRead': false,
    },
    {
      'icon': Icons.shopping_cart,
      'title': 'Large Order Placed',
      'subtitle': 'Order #12345 for \$500 has been placed.',
      'time': '1 hour ago',
      'isRead': false,
    },
    {
      'icon': Icons.error,
      'title': 'System Alert',
      'subtitle': 'Server maintenance scheduled for tonight at 2 AM.',
      'time': '3 hours ago',
      'isRead': true,
    },
    {
      'icon': Icons.person_add,
      'title': 'New User Signup',
      'subtitle': 'A new user "John Doe" has signed up.',
      'time': '1 day ago',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: ThemeColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Action to clear all notifications
              setState(() {
                _notifications.clear();
              });
            },
          ),
        ],
      ),
      backgroundColor: ThemeColors.scaffoldBackground,
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification['isRead'] ? Colors.grey.shade300 : ThemeColors.accent,
                      foregroundColor: notification['isRead'] ? Colors.grey.shade700 : Colors.white,
                      child: Icon(notification['icon']),
                    ),
                    title: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notification['subtitle']),
                    trailing: Text(
                      notification['time'],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      setState(() {
                        notification['isRead'] = true;
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}
