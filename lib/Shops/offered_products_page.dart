import 'package:flutter/material.dart';
import 'package:cart_link/Shops/create_offer_page.dart';
import 'package:cart_link/shared/notification_actions.dart';

class OfferedProductsPage extends StatefulWidget {
  const OfferedProductsPage({super.key});

  @override
  State<OfferedProductsPage> createState() => _OfferedProductsPageState();
}

class _OfferedProductsPageState extends State<OfferedProductsPage> {
  late final List<Map<String, dynamic>> _offeredProducts = [
    {
      'id': 1,
      'name': 'Wireless Headphones',
      'originalPrice': 2500,
      'offerPrice': 1999,
      'discount': 20,
      'startDate': 'Nov 24, 2024',
      'endDate': 'Dec 10, 2024',
      'status': 'Active',
    },
    {
      'id': 2,
      'name': 'Bluetooth Speaker',
      'originalPrice': 1800,
      'offerPrice': 1350,
      'discount': 25,
      'startDate': 'Nov 25, 2024',
      'endDate': 'Dec 05, 2024',
      'status': 'Active',
    },
    {
      'id': 3,
      'name': 'Phone Case',
      'originalPrice': 500,
      'offerPrice': 349,
      'discount': 30,
      'startDate': 'Nov 20, 2024',
      'endDate': 'Nov 30, 2024',
      'status': 'Expiring Soon',
    },
    {
      'id': 4,
      'name': 'Laptop Stand',
      'originalPrice': 1200,
      'offerPrice': 899,
      'discount': 25,
      'startDate': 'Nov 26, 2024',
      'endDate': 'Dec 15, 2024',
      'status': 'Active',
    },
  ];

  void _showEditOfferDialog(BuildContext context, int index) {
    final offer = _offeredProducts[index];
    final priceController = TextEditingController(
      text: offer['offerPrice'].toString(),
    );
    final endDateController = TextEditingController(text: offer['endDate']);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Product: '),
              Text(
                offer['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Offer Price',
                  prefixText: '₹',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: endDateController,
                decoration: const InputDecoration(
                  labelText: 'End Date (e.g., Dec 20, 2024)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _offeredProducts[index]['offerPrice'] =
                    int.tryParse(priceController.text) ?? offer['offerPrice'];
                _offeredProducts[index]['endDate'] = endDateController.text;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Offer updated')));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showExtendOfferDialog(BuildContext context, int index) {
    final offer = _offeredProducts[index];
    final endDateController = TextEditingController(text: offer['endDate']);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current End Date: ${offer['endDate']}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: endDateController,
                decoration: const InputDecoration(
                  labelText: 'New End Date (e.g., Jan 05, 2025)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _offeredProducts[index]['endDate'] = endDateController.text;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Offer extended')));
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  void _endOffer(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Offer'),
        content: const Text('Are you sure you want to end this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _offeredProducts.removeAt(index);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Offer ended')));
            },
            child: const Text('End Offer'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Active') return Colors.green;
    if (status == 'Expiring Soon') return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offered Products'),
        actions: const [NotificationActions(), SizedBox(width: 8)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: _offeredProducts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = _offeredProducts[index];
            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₹${product['originalPrice']}',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${product['offerPrice']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${product['discount']}%',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product['startDate']} - ${product['endDate']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              product['status'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product['status'],
                            style: TextStyle(
                              color: _getStatusColor(product['status']),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showEditOfferDialog(context, index),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showExtendOfferDialog(context, index),
                          icon: const Icon(Icons.schedule, size: 16),
                          label: const Text('Extend'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _endOffer(index),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('End'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateOfferPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Offer'),
      ),
    );
  }
}
