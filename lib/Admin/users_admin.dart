import 'package:flutter/material.dart';
import '../theme_data.dart';

class UsersAdmin extends StatefulWidget {
  const UsersAdmin({super.key});

  @override
  State<UsersAdmin> createState() => _UsersAdminState();
}

class User {
  final String id;
  final String name;
  final String location;
  final String profileUrl; // Optional, can be empty
  final int totalOrders;
  final String info;

  User({
    required this.id,
    required this.name,
    required this.location,
    this.profileUrl = '',
    required this.totalOrders,
    required this.info,
  });
}

class _UsersAdminState extends State<UsersAdmin> {
  final List<User> _users = [
    User(
      id: 'USR-001',
      name: 'Asha Patel',
      location: 'Mumbai',
      profileUrl: '',
      totalOrders: 12,
      info: 'Joined: 2023-02-12\nPreferred: Grocery',
    ),
    User(
      id: 'USR-002',
      name: 'Rahul Kumar',
      location: 'Delhi',
      profileUrl: '',
      totalOrders: 5,
      info: 'Joined: 2024-01-05\nPreferred: Electronics',
    ),
    User(
      id: 'USR-003',
      name: 'Meera Singh',
      location: 'Bengaluru',
      profileUrl: '',
      totalOrders: 8,
      info: 'Joined: 2022-11-20\nPreferred: Fashion',
    ),
    User(
      id: 'USR-004',
      name: 'Karan Rao',
      location: 'Chennai',
      profileUrl: '',
      totalOrders: 3,
      info: 'Joined: 2024-06-02\nPreferred: Vegetables',
    ),
    User(
      id: 'USR-005',
      name: 'Lina George',
      location: 'Kochi',
      profileUrl: '',
      totalOrders: 20,
      info: 'Joined: 2021-08-14\nPreferred: Books',
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  void _showInfo(User user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${user.id}'),
            const SizedBox(height: 8),
            Text('Location: ${user.location}'),
            const SizedBox(height: 8),
            Text('Total Orders: ${user.totalOrders}'),
            const SizedBox(height: 8),
            Text('Info:\n${user.info}'),
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

  void _showAddDialog() {
    _nameController.clear();
    _locationController.clear();
    _infoController.clear();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter location' : null,
              ),
              TextFormField(
                controller: _infoController,
                decoration: const InputDecoration(labelText: 'Info'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                final newId =
                    'USR-${(_users.length + 1).toString().padLeft(3, '0')}';
                setState(() {
                  _users.add(
                    User(
                      id: newId,
                      name: _nameController.text.trim(),
                      location: _locationController.text.trim(),
                      totalOrders: 0,
                      info: _infoController.text.trim(),
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: ThemeColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: ThemeColors.accent,
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.resolveWith(
                      (states) => ThemeColors.primary,
                    ),
                    headingRowHeight: 56,
                    dataRowHeight: 70,
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
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Total Orders',
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
                    rows: List.generate(_users.length, (index) {
                      final u = _users[index];
                      return DataRow(
                        cells: [
                          DataCell(Text(u.id)),
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.shade200,
                                  child: Text(
                                    u.name.isNotEmpty ? u.name[0] : '?',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(u.name),
                              ],
                            ),
                          ),
                          DataCell(Text(u.location)),
                          DataCell(Text(u.totalOrders.toString())),
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
              ),
            ),
          );
        },
      ),
    );
  }
}
