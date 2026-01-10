import 'package:flutter/material.dart';
import '../theme_data.dart';

class CustomerReportShopsPage extends StatefulWidget {
  const CustomerReportShopsPage({super.key});

  @override
  State<CustomerReportShopsPage> createState() =>
      _CustomerReportShopsPageState();
}

class _CustomerReportShopsPageState extends State<CustomerReportShopsPage> {
  // Mock reported shops data
  final List<Map<String, dynamic>> _reportedShops = [
    {
      'id': 'RS001',
      'shopName': 'Fake Electronics Store',
      'ownerName': 'John Seller',
      'reason': 'Selling counterfeit products',
      'reportedDate': DateTime(2024, 11, 22, 10, 30),
      'status': 'Pending',
      'reportedBy': 'Customer',
      'details':
          'Purchased item labeled as original but received counterfeit product',
    },
    {
      'id': 'RS002',
      'shopName': 'Suspicious Fashion Hub',
      'ownerName': 'Sarah Boutique',
      'reason': 'Undelivered orders',
      'reportedDate': DateTime(2024, 11, 21, 14, 15),
      'status': 'Under Review',
      'reportedBy': 'Customer',
      'details': 'Ordered 3 items 15 days ago, none have been delivered',
    },
    {
      'id': 'RS003',
      'shopName': 'Quick Deal Store',
      'ownerName': 'Quick Deal Admin',
      'reason': 'Misleading product descriptions',
      'reportedDate': DateTime(2024, 11, 20, 9, 45),
      'status': 'Resolved',
      'reportedBy': 'Customer',
      'details':
          'Product size and color different from description. Shop refunded amount.',
    },
    {
      'id': 'RS004',
      'shopName': 'Bulk Traders',
      'ownerName': 'Bulk Admin',
      'reason': 'Poor customer service',
      'reportedDate': DateTime(2024, 11, 19, 16, 20),
      'status': 'Pending',
      'reportedBy': 'Customer',
      'details':
          'Multiple attempts to contact shop regarding damaged product, no response',
    },
    {
      'id': 'RS005',
      'shopName': 'Premium Mart',
      'ownerName': 'Premium Owner',
      'reason': 'Overcharging delivery fees',
      'reportedDate': DateTime(2024, 11, 18, 11, 10),
      'status': 'Under Review',
      'reportedBy': 'Customer',
      'details': 'Delivery fee was double the amount shown in initial checkout',
    },
  ];

  String _filterStatus = 'All'; // 'All', 'Pending', 'Under Review', 'Resolved'
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredReports {
    List<Map<String, dynamic>> filtered = _reportedShops;

    // Apply status filter
    if (_filterStatus != 'All') {
      filtered = filtered.where((r) => r['status'] == _filterStatus).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (r) =>
                r['shopName'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                r['ownerName'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                r['reason'].toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return ThemeColors.warning;
      case 'Under Review':
        return ThemeColors.info;
      case 'Resolved':
        return ThemeColors.success;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Shop'), elevation: 0,
      backgroundColor: ThemeColors.primary,
      foregroundColor: ThemeColors.textColorWhite,),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search shop name, owner, or reason...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          // Status filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filterStatus == 'All',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterStatus = 'All';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Pending'),
                  selected: _filterStatus == 'Pending',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterStatus = 'Pending';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Under Review'),
                  selected: _filterStatus == 'Under Review',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterStatus = 'Under Review';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Resolved'),
                  selected: _filterStatus == 'Resolved',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterStatus = 'Resolved';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Reports list
          Expanded(
            child: _filteredReports.isEmpty
                ? Center(
                    child: Text(
                      'No reports found',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filteredReports.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      final status = report['status'] as String;
                      final statusColor = _getStatusColor(status);
                      final reportedDate = report['reportedDate'] as DateTime;

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withOpacity(0.2),
                            child: Text(
                              report['shopName']
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            report['shopName'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Reason: ${report['reason']}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Reported: ${reportedDate.day}/${reportedDate.month}/${reportedDate.year}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              status,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor: statusColor,
                          ),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Report ${report['id']}'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Shop: ${report['shopName']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Owner: ${report['ownerName']}'),
                                      const SizedBox(height: 8),
                                      Text('Reason: ${report['reason']}'),
                                      const SizedBox(height: 8),
                                      Text('Details: ${report['details']}'),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Reported Date: ${reportedDate.day}/${reportedDate.month}/${reportedDate.year} ${reportedDate.hour}:${reportedDate.minute.toString().padLeft(2, '0')}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Status: ${report['status']}'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
