// import 'dart:convert';
// import 'package:cart_link/Customer/customer_home.dart';
import 'package:cart_link/services/customer_service.dart';
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import '../theme_data.dart';

class UsersAdmin extends StatefulWidget {
  const UsersAdmin({super.key});

  @override
  State<UsersAdmin> createState() => _UsersAdminState();
}

class User {
  final String id;
  final String customerName;
  final String email;
  final int mobile;
  final String address;
  DateTime? createdAt;
  final String profileUrl; // Optional, can be empty
  // int totalOrders;
  // String info;

  User({
    required this.id,
    required this.customerName,
    required this.email,
    required this.mobile,
    required this.address,
    this.createdAt,
    this.profileUrl = '',
    // this.totalOrders,
    // this.info,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      customerName: json['customerName'] ?? '',
      address: json['address'] ?? '',
      mobile: json['mobile'] ?? 0,
      email: json['email'],
      // totalOrders: json['totalOrders'],
      // info: json['info'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}

class _UsersAdminState extends State<UsersAdmin> {
  List<User> _customers = [];
  bool _loading = true;

  // Change this base URL depending on where your backend runs.
  // On Android emulator use 10.0.2.2, on desktop use localhost.
  // final String _baseUrl = 'http://10.0.2.2:5000';

  // Note: Add-user UI removed. Data is loaded from backend only.

  @override
  void dispose() {
    // No controllers to dispose (add-user removed)
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final result = await CustomerService.getAllCustomers();
      if (mounted) {
        if (result['success'] == true) {
          // print('Customer loadede');
          final List<dynamic> customerJson = result['data'] ?? [];
          setState(() {
            _customers = customerJson.map((s) => User.fromJson(s)).toList();
            // print(_customers);
          });
        } else {
          _showErrorDialog(
            'Error',
            result['message'] ?? 'Failed to load customer',
          );
        }
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Error', 'Failed to load customer: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showInfo(User user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.customerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${user.id}'),
            const SizedBox(height: 8),
            // const SizedBox(height: 8),
            // Text('Total Orders: ${user.totalOrders}'),
            // const SizedBox(height: 8),
            // Text('Info:\n${user.info}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } // Add-user functionality removed: users are managed via backend

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: ThemeColors.primary,
        foregroundColor: Colors.white,
      ),
      // Add button removed: users are added via backend
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Horizontal scroll outside, vertical scroll inside so table can grow
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    // Only enforce minimum width so the table can grow vertically
                    // and the outer vertical SingleChildScrollView will scroll.
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.resolveWith(
                        (states) => ThemeColors.primary,
                      ),
                      headingRowHeight: 56,
                      dataRowMinHeight: 70,
                      dataRowMaxHeight: 70,
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'User ID',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'User Name',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        DataColumn(
                          label: Text(
                            'Mobile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Info',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      rows: List.generate(_customers.length, (index) {
                        final u = _customers[index];
                        return DataRow(
                          cells: [
                            DataCell(Text(u.id)),
                            DataCell(Text(u.customerName)),
                            // Mobile shown here
                            DataCell(Text(u.mobile.toString())),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.info_outline),
                                tooltip: 'Info',
                                onPressed: () => _showInfo(u),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
