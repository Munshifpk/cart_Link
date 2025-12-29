import 'package:flutter/material.dart';
// import 'login-Shops.dart';
import '../main.dart';
import '../services/auth_state.dart';

class ShopSettingsPage extends StatefulWidget {
  const ShopSettingsPage({super.key});

  @override
  State<ShopSettingsPage> createState() => _ShopSettingsPageState();
}

class _ShopSettingsPageState extends State<ShopSettingsPage> {
  bool _notifications = true;
  bool _autoAcceptOrders = false;
  bool _darkMode = false;

  Future<void> _confirmAndLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear shop owner session
      await AuthState.logoutOwner();
      
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.storefront)),
            title: Text('Your Shop'),
            subtitle: Text('Manage account and shop details'),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Receive order & customer alerts'),
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Auto-accept orders'),
                  subtitle: const Text('Automatically confirm incoming orders'),
                  value: _autoAcceptOrders,
                  onChanged: (v) => setState(() => _autoAcceptOrders = v),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Dark mode'),
                  subtitle: const Text('Use dark theme in the app'),
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Account'),
                  subtitle: const Text('Update owner info & password'),
                  onTap: () {
                    // TODO: navigate to account details page
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.payment_outlined),
                  title: const Text('Payment & Payouts'),
                  subtitle: const Text('Manage payout methods'),
                  onTap: () {},
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: const Text('Order History'),
                  subtitle: const Text('View past orders & invoices'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => {_confirmAndLogout()},
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              // Quick access: go back to dashboard/home
              Navigator.pop(context);
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }
}
