import 'package:flutter/material.dart';
import 'package:cart_link/Customer/notification_offers.dart';

class NotificationActions extends StatelessWidget {
  const NotificationActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_active_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OffersFollowedShopsPage(),
              ),
            );
          },
        ),
        // App updates link removed as requested
      ],
    );
  }
}
