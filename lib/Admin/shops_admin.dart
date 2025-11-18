import 'package:flutter/material.dart';
import '../services/shop_service.dart';
import 'dart:math' as math; // added

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

  Shop({
    this.id,
    required this.name,
    required this.address,
    required this.mobile,
    this.email,
    this.ownerName,
    this.businessType,
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
            _shops = shopsJson.map((shop) => Shop.fromJson(shop)).toList();
          });
          print('✅ Loaded ${_shops.length} shops');
          for (var s in _shops) {
            print('Shop: id=${s.id} name=${s.name} mobile=${s.mobile} owner=${s.ownerName}');
          }
        } else {
          _showErrorDialog('Error', result['message'] ?? 'Failed to load shops');
        }
      }
    } catch (e) {
      print('❌ Error loading shops: $e');
      if (mounted) {
        _showErrorDialog('Error', 'Failed to load shops: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShops,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
              ? const Center(child: Text('No shops found'))
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalPadding = 24.0; // left + right internal spacing
                      final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width;
                      final availableW = (maxW - totalPadding).clamp(200.0, double.infinity);

                      // Use the available height from LayoutBuilder so table fills the screen
                      final availableH = constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.vertical;

                      // Column flexes (adjust if you want different proportions)
                      const nameFlex = 3;
                      const ownerFlex = 2;
                      const locationFlex = 3;
                      const contactFlex = 2;
                      const infoFlex = 1;
                      const totalFlex = nameFlex + ownerFlex + locationFlex + contactFlex + infoFlex;

                      final nameW = availableW * (nameFlex / totalFlex);
                      final ownerW = availableW * (ownerFlex / totalFlex);
                      final locationW = availableW * (locationFlex / totalFlex);
                      final contactW = availableW * (contactFlex / totalFlex);
                      final infoW = math.max(availableW * (infoFlex / totalFlex), 48.0); // changed: ensure min width

                      return SizedBox(
                        height: availableH,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              // allow table to shrink on small screens (minWidth 0),
                              // but we set the DataTable width to availableW so columns scale down.
                              constraints: BoxConstraints(minWidth: 0, minHeight: availableH),
                              child: SizedBox(
                                width: availableW,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.resolveWith(
                                    (states) => const Color(0xFFEEEEEE),
                                  ),
                                  columns: [
                                    DataColumn(
                                      label: SizedBox(width: nameW, child: const Text('Shop Name')),
                                    ),
                                    DataColumn(
                                      label: SizedBox(width: ownerW, child: const Text('Owner')),
                                    ),
                                    DataColumn(
                                      label: SizedBox(width: locationW, child: const Text('Location')),
                                    ),
                                    DataColumn(
                                      label: SizedBox(width: contactW, child: const Text('Contact')),
                                    ),
                                    DataColumn(
                                      // header with text "Info" and a small icon beside it
                                      label: SizedBox(
                                        width: infoW,
                                        child: Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('Info'),
                                              const SizedBox(width: 6),
                                              Icon(Icons.info_outline, size: 16, color: Theme.of(context).primaryColor),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: List.generate(_shops.length, (index) {
                                    final shop = _shops[index];
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          SizedBox(
                                            width: nameW,
                                            child: Text(
                                              shop.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: ownerW,
                                            child: Text(
                                              shop.ownerName ?? '',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: locationW,
                                            child: Text(
                                              shop.address,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: contactW,
                                            child: Text(
                                              shop.mobile.toString(),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: infoW,
                                            child: Center(
                                              child: IconButton(
                                                padding: const EdgeInsets.all(6),
                                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                                icon: Icon(Icons.info_outline, size: 20, color: Theme.of(context).primaryColor),
                                                tooltip: 'Details',
                                                onPressed: () => _showShopDetails(shop),
                                              ),
                                              
                                            ),
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
                      );
                    },
                  ),
                ),
    );
  }
}
