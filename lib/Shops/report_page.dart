import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // Mock reported users data
  final List<Map<String, dynamic>> _reportedUsers = [
    {
      'id': 'R001',
      'userName': 'john_doe',
      'email': 'john@example.com',
      'reason': 'Fraudulent activity',
      'reportedDate': DateTime(2024, 11, 22, 10, 30),
      'status': 'Pending',
      'reportedBy': 'Customer',
    },
    {
      'id': 'R002',
      'userName': 'suspicious_seller',
      'email': 'seller@example.com',
      'reason': 'Selling counterfeit items',
      'reportedDate': DateTime(2024, 11, 21, 14, 15),
      'status': 'Under Review',
      'reportedBy': 'Admin',
    },
    {
      'id': 'R003',
      'userName': 'fake_account',
      'email': 'fake@example.com',
      'reason': 'Inappropriate behavior',
      'reportedDate': DateTime(2024, 11, 20, 9, 45),
      'status': 'Resolved',
      'reportedBy': 'Customer',
    },
    {
      'id': 'R004',
      'userName': 'spam_bot',
      'email': 'bot@example.com',
      'reason': 'Spam and harassment',
      'reportedDate': DateTime(2024, 11, 19, 16, 20),
      'status': 'Pending',
      'reportedBy': 'System',
    },
    {
      'id': 'R005',
      'userName': 'scammer123',
      'email': 'scam@example.com',
      'reason': 'Payment fraud',
      'reportedDate': DateTime(2024, 11, 18, 11, 10),
      'status': 'Under Review',
      'reportedBy': 'Customer',
    },
  ];

  String _filterStatus = 'All'; // 'All', 'Pending', 'Under Review', 'Resolved'
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredReports {
    List<Map<String, dynamic>> filtered = _reportedUsers;

    // Apply status filter
    if (_filterStatus != 'All') {
      filtered = filtered.where((r) => r['status'] == _filterStatus).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (r) =>
                r['userName'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                r['email'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r['reason'].toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Under Review':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), elevation: 0),
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
                hintText: 'Search user, email, or reason...',
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
                              report['userName']
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
                            report['userName'],
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
                                        'User: ${report['userName']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Email: ${report['email']}'),
                                      const SizedBox(height: 8),
                                      Text('Reason: ${report['reason']}'),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Reported Date: ${reportedDate.day}/${reportedDate.month}/${reportedDate.year} ${reportedDate.hour}:${reportedDate.minute.toString().padLeft(2, '0')}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Status: ${report['status']}'),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Reported By: ${report['reportedBy']}',
                                      ),
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
