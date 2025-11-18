import 'package:flutter/material.dart';

class ShopsAdmin extends StatefulWidget {
  const ShopsAdmin({super.key});

  @override
  State<ShopsAdmin> createState() => _ShopsAdminState();
}

class Shop {
  String name;
  String location;
  String contact;

  Shop({required this.name, required this.location, required this.contact});
}

class _ShopsAdminState extends State<ShopsAdmin> {
  final List<Shop> _shops = [
    Shop(name: 'Fresh Mart', location: 'Downtown', contact: '+919876543210'),
    Shop(name: 'Tech World', location: 'City Center', contact: '+919812345678'),
    Shop(name: 'Fashion Hub', location: 'Mall Road', contact: '+919834567890'),
    Shop(
      name: 'Green Grocers',
      location: 'Market Street',
      contact: '+919845612378',
    ),
    Shop(
      name: 'Book Haven',
      location: 'Library Lane',
      contact: '+919856789012',
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    _nameController.clear();
    _locationController.clear();
    _contactController.clear();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Shop'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Shop name'),
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
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact number'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter contact' : null,
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
                setState(() {
                  _shops.add(
                    Shop(
                      name: _nameController.text.trim(),
                      location: _locationController.text.trim(),
                      contact: _contactController.text.trim(),
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

  void _showShopDetails(Shop shop) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shop.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${shop.location}'),
            const SizedBox(height: 8),
            Text('Contact: ${shop.contact}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _shops.isEmpty
            ? const Center(child: Text('No shops yet'))
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.resolveWith(
                              (states) => const Color(0xFFEEEEEE),
                            ),
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Location')),
                              DataColumn(label: Text('Contact')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: List.generate(_shops.length, (index) {
                              final s = _shops[index];
                              return DataRow(
                                cells: [
                                  DataCell(Text(s.name)),
                                  DataCell(Text(s.location)),
                                  DataCell(Text(s.contact)),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline),
                                          tooltip: 'Details',
                                          onPressed: () => _showShopDetails(s),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showEditDialog(int index) {
    final shop = _shops[index];
    _nameController.text = shop.name;
    _locationController.text = shop.location;
    _contactController.text = shop.contact;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Shop'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Shop name'),
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
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact number'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter contact' : null,
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
                setState(() {
                  _shops[index] = Shop(
                    name: _nameController.text.trim(),
                    location: _locationController.text.trim(),
                    contact: _contactController.text.trim(),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteShop(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop'),
        content: const Text('Are you sure you want to delete this shop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _shops.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
