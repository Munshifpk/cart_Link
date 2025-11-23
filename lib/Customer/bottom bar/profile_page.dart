import 'package:cart_link/main.dart' as app_main;
import 'package:flutter/material.dart';
import '../customer_home.dart';

class CustomerProfilePage extends StatelessWidget {
  final Customer? customer;
  const CustomerProfilePage({super.key, this.customer});

  @override
  Widget build(BuildContext context) {
    final name = customer?.customerName ?? 'Unknown';
    final email = customer?.email ?? '—';
    final mobile = customer?.mobile?.toString() ?? '—';
    final address = customer?.address ?? '—';

    return ListView(
      key: const PageStorageKey('profile'),
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.email_outlined),
          title: const Text('Email'),
          subtitle: Text(email),
        ),
        ListTile(
          leading: const Icon(Icons.phone_outlined),
          title: const Text('Mobile'),
          subtitle: Text(mobile),
        ),
        ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Address'),
          subtitle: Text(address),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Orders'),
            leading: const Icon(Icons.list),
            onTap: () {},
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Settings'),
            leading: const Icon(Icons.settings),
            onTap: () {},
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => app_main.HomePage()),
              );
            },
          ),
        ),
      ],
    );
  }
}
