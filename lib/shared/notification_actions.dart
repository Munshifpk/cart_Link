import 'package:flutter/material.dart';
import 'package:cart_link/Customer/notification_offers.dart';

class NotificationActions extends StatelessWidget {
  final int badgeCount;
  final Future<void> Function()? onAfterNavigate;

  const NotificationActions({
    super.key,
    this.badgeCount = 0,
    this.onAfterNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_active_outlined),
              if (badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OffersFollowedShopsPage(),
              ),
            );
            if (onAfterNavigate != null) {
              await onAfterNavigate!();
            }
          },
        ),
        // App updates link removed as requested
      ],
    );
  }
}
