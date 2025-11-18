import 'package:flutter/material.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final List<_Item> _notifications = List.generate(
    6,
    (i) => _Item(
      id: 'n$i',
      title: i.isEven ? 'New message from customer' : 'Price alert',
      subtitle: i.isEven
          ? 'Customer asked about product availability.'
          : 'One of your items is trending.',
      time: DateTime.now().subtract(Duration(minutes: i * 12 + 5)),
      isRead: i.isEven ? false : true,
      type: _ItemType.notification,
    ),
  );

  final List<_Item> _orders = List.generate(
    5,
    (i) => _Item(
      id: 'o$i',
      title: 'Order #ORD${200 + i}',
      subtitle: i.isEven ? 'Delivered • ${5 + i} items' : 'New order placed',
      time: DateTime.now().subtract(Duration(hours: i + 1)),
      isRead: i.isEven ? true : false,
      type: _ItemType.order,
    ),
  );

  void _markAllRead(_ItemType type) {
    setState(() {
      final list = type == _ItemType.notification ? _notifications : _orders;
      for (var it in list) {
        it.isRead = true;
      }
    });
  }

  void _clearAll(_ItemType type) {
    setState(() {
      if (type == _ItemType.notification) {
        _notifications.clear();
      } else {
        _orders.clear();
      }
    });
  }

  Widget _buildList(List<_Item> items, _ItemType type) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            type == _ItemType.notification ? 'No notifications' : 'No orders',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            setState(() {
              items.removeAt(index);
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Removed')));
          },
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: item.type == _ItemType.order
                      ? Colors.blue.shade50
                      : Colors.green.shade50,
                  child: Icon(
                    item.type == _ItemType.order
                        ? Icons.shopping_bag_outlined
                        : Icons.notifications_outlined,
                    color: item.type == _ItemType.order
                        ? Colors.blue
                        : Colors.green,
                  ),
                ),
                if (!item.isRead)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: item.isRead ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            subtitle: Text(item.subtitle),
            trailing: Text(
              _timeAgo(item.time),
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
            onTap: () => _openDetail(item),
            onLongPress: () {
              setState(() => item.isRead = true);
            },
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _openDetail(_Item item) {
    setState(() => item.isRead = true);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.subtitle),
            const SizedBox(height: 12),
            Text('Received: ${item.time}'),
            if (item.type == _ItemType.order)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Order actions: Accept • Prepare • Ship',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (item.type == _ItemType.order)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Order opened')));
              },
              child: const Text('Open Order'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications Center'),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Notifications'),
              Tab(text: 'Orders'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'mark_all_notifications') {
                  _markAllRead(_ItemType.notification);
                }
                if (v == 'clear_notifications') {
                  _clearAll(_ItemType.notification);
                }
                if (v == 'mark_all_orders') _markAllRead(_ItemType.order);
                if (v == 'clear_orders') _clearAll(_ItemType.order);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'mark_all_notifications',
                  child: Text('Mark all notifications read'),
                ),
                const PopupMenuItem(
                  value: 'clear_notifications',
                  child: Text('Clear notifications'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'mark_all_orders',
                  child: Text('Mark all orders read'),
                ),
                const PopupMenuItem(
                  value: 'clear_orders',
                  child: Text('Clear orders'),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 700));
                // fake refresh
              },
              child: _buildList(_notifications, _ItemType.notification),
            ),
            RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 700));
              },
              child: _buildList(_orders, _ItemType.order),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ItemType { notification, order }

class _Item {
  final String id;
  final String title;
  final String subtitle;
  final DateTime time;
  bool isRead;
  final _ItemType type;

  _Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isRead = false,
    required this.type,
  });
}
