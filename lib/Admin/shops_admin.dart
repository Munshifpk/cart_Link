import 'package:flutter/material.dart';

class ShopsAdmin extends StatefulWidget {
  const ShopsAdmin({super.key});

  @override
  State<ShopsAdmin> createState() => _ShopsAdminState();
}

class Shop {
  String? id;
  String name;
  String address;
  int mobile;
  String? email;
  String? ownerName;
  String? businessType;
  String? taxId;

  Shop({
    this.id,
    required this.name,
    required this.address,
    required this.mobile,
    this.email,
    this.ownerName,
    this.businessType,
    this.taxId,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['_id'],
      name: json['shopName'] ?? '',
      address: json['address'] ?? '',
      mobile: json['mobile'] ?? 0,
      email: json['email'],
      ownerName: json['ownerName'],
      businessType: json['businessType'],
      taxId: json['taxId'],
    );
  }
}

class _ShopsAdminState extends State<ShopsAdmin> {
  List<Shop> _shops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() => _loading = true);
    try {
      final result = await ShopService.getAllShops();
      if (mounted) {
        if (result['success'] == true) {
          final List<dynamic> shopsJson = result['data'] ?? [];
          setState(() {
            _shops = shopsJson.map((s) => Shop.fromJson(s)).toList();
          });
        } else {
          _showErrorDialog('Error', result['message'] ?? 'Failed to load shops');
        }
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Error', 'Failed to load shops: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            Text('Owner: ${shop.ownerName ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Location: ${shop.address}'),
            const SizedBox(height: 8),
            Text('Mobile: ${shop.mobile.toString()}'),
            const SizedBox(height: 8),
            Text('Email: ${shop.email ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Type: ${shop.businessType ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Tax ID: ${shop.taxId ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops'),
        backgroundColor: AdminTheme.primary,
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
                ),
    );
  }
}
