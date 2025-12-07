import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/auth_state.dart';

class EventOffersPage extends StatefulWidget {
  const EventOffersPage({super.key});

  @override
  State<EventOffersPage> createState() => _EventOffersPageState();
}

class _EventOffersPageState extends State<EventOffersPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _percentageController = TextEditingController();
  final _eventSearchController = TextEditingController();
  bool _usePercentage = false;

  // Predefined events
  final List<String> _availableEvents = [
    'Onam Special Offer',
    'Christmas Sale',
    'New Year Discount',
    'Diwali Bonanza',
    'Valentine\'s Day Offer',
    'Summer Flash Sale',
    'Black Friday Deal',
    'Cyber Monday',
  ];

  // Sample products (same as in CreateOfferPage)
  List<Map<String, dynamic>> _products = [];
  // ignore: unused_field
  bool _isLoadingProducts = false;

  String _selectedEvent = '';
  Set<String> _selectedProducts = {};
  DateTime? _eventStartDate;
  DateTime? _eventEndDate;
  List<Map<String, dynamic>> _publishedOffers = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    // Get current shop owner ID from AuthState
    final ownerId = AuthState.currentOwner?['_id'] as String?;
    if (ownerId == null) {
      setState(() => _isLoadingProducts = false);
      return;
    }
    final result = await ProductService.getProducts(ownerId: ownerId);
    if (result['success'] && result['data'] is List) {
      var rawProducts = result['data'] as List;

      // Fetch images for each product
      final productsWithImages = await Future.wait(rawProducts.map<Future<Map<String, dynamic>>>((p) async {
        final Map<String, dynamic> map = Map<String, dynamic>.from(p as Map);
        try {
          final id = (map['_id'] ?? map['id'] ?? '').toString();
          if (id.isNotEmpty) {
            final imgs = await ProductService.getProductImages(id);
            if (imgs.isNotEmpty) map['images'] = imgs;
          }
        } catch (_) {}
        return map;
      }));

      final fetchedProducts = productsWithImages
          .map(
            (p) => {
              'name': p['name'] ?? 'Unknown',
              'price': p['price'] ?? 0,
              'mrp': p['mrp'] ?? p['price'] ?? 0,
              'images': p['images'],
            },
          )
          .toList();
      setState(() {
        _products = fetchedProducts;
        _isLoadingProducts = false;
      });
    } else {
      setState(() => _isLoadingProducts = false);
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _priceController.dispose();
    _percentageController.dispose();
    _eventSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({
    required bool isStart,
    required void Function(DateTime) onPicked,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime = date.copyWith(
          hour: time.hour,
          minute: time.minute,
          second: 0,
        );
        onPicked(dateTime);
      }
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Select date & time';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _publishOffer() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEvent.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an event')));
      return;
    }

    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one product')),
      );
      return;
    }

    if (_eventStartDate == null || _eventEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (_eventStartDate!.isAfter(_eventEndDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start date must be before end date')),
      );
      return;
    }

    final offer = {
      'event': _selectedEvent,
      'products': _selectedProducts.toList(),
      'startDate': _eventStartDate,
      'endDate': _eventEndDate,
      'offerType': _usePercentage ? 'percentage' : 'fixed',
      'offerValue': _usePercentage
          ? double.parse(_percentageController.text)
          : double.parse(_priceController.text),
      'publishedAt': DateTime.now(),
    };

    setState(() {
      _publishedOffers.add(offer);
    });

    // Reset form
    _formKey.currentState!.reset();
    _eventNameController.clear();
    _priceController.clear();
    _percentageController.clear();
    _selectedEvent = '';
    _selectedProducts.clear();
    _eventStartDate = null;
    _eventEndDate = null;
    _usePercentage = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ Event offer published: $_selectedEvent with ${_selectedProducts.length} products',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Offers')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Event Offer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Event Selection Dropdown
                      const Text('Select Event'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedEvent.isEmpty ? null : _selectedEvent,
                        items: _availableEvents.map((event) {
                          return DropdownMenuItem(
                            value: event,
                            child: Text(event),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedEvent = value ?? '');
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Onam Special Offer',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Select an event' : null,
                      ),
                      const SizedBox(height: 12),
                      // Product Selection Section
                      const Text('Select Products'),
                      const SizedBox(height: 8),
                      ListTile(
                        title: const Text('Browse & Add Products'),
                        trailing: const Icon(Icons.search),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        onTap: () => _showProductSearchDialog(),
                      ),
                      const SizedBox(height: 8),
                      // Selected Products with Search
                      if (_selectedProducts.isNotEmpty) ...[
                        TextField(
                          controller: _eventSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search selected products...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selected: ${_selectedProducts.where((p) => p.toLowerCase().contains(_eventSearchController.text.toLowerCase().trim())).length} of ${_selectedProducts.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _selectedProducts
                              .where(
                                (name) => name.toLowerCase().contains(
                                  _eventSearchController.text
                                      .toLowerCase()
                                      .trim(),
                                ),
                              )
                              .map((name) {
                                return Chip(
                                  label: Text(name),
                                  onDeleted: () => setState(
                                    () => _selectedProducts.remove(name),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No products selected',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Offer Type Toggle
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: !_usePercentage
                                  ? null
                                  : () =>
                                        setState(() => _usePercentage = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !_usePercentage
                                    ? Colors.blue
                                    : Colors.grey[300],
                              ),
                              child: Text(
                                'Fixed Price',
                                style: TextStyle(
                                  color: !_usePercentage
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _usePercentage
                                  ? null
                                  : () => setState(() => _usePercentage = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _usePercentage
                                    ? Colors.blue
                                    : Colors.grey[300],
                              ),
                              child: Text(
                                'Percentage',
                                style: TextStyle(
                                  color: _usePercentage
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Offer Price or Percentage
                      if (!_usePercentage) ...[
                        const Text('Offer Price'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: '₹',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter price';
                            if (double.tryParse(v) == null)
                              return 'Enter valid number';
                            return null;
                          },
                        ),
                      ] else ...[
                        const Text('Discount Percentage'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _percentageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            suffixText: '%',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Enter percentage';
                            final num = double.tryParse(v);
                            if (num == null) return 'Enter valid number';
                            if (num < 0 || num > 100)
                              return 'Enter percentage between 0-100';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Event Start Date
                      const Text('Event Start (date & time)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                          text: _formatDateTime(_eventStartDate),
                        ),
                        onTap: () => _pickDateTime(
                          isStart: true,
                          onPicked: (dt) =>
                              setState(() => _eventStartDate = dt),
                        ),
                        validator: (v) => (_eventStartDate == null)
                            ? 'Select start date'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Event End Date
                      const Text('Event End (date & time)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                          text: _formatDateTime(_eventEndDate),
                        ),
                        onTap: () => _pickDateTime(
                          isStart: false,
                          onPicked: (dt) => setState(() => _eventEndDate = dt),
                        ),
                        validator: (v) =>
                            (_eventEndDate == null) ? 'Select end date' : null,
                      ),
                      const SizedBox(height: 16),
                      // Publish Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _publishOffer,
                          icon: const Icon(Icons.publish),
                          label: const Text('Publish Event Offer'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Published Offers Section
            Text(
              'Published Offers (${_publishedOffers.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_publishedOffers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No event offers published yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _publishedOffers.length,
                itemBuilder: (context, index) {
                  final offer = _publishedOffers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  offer['event'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => setState(
                                  () => _publishedOffers.removeAt(index),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Products: ${(offer['products'] as List).join(', ')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Period: ${_formatDateTime(offer['startDate'])} to ${_formatDateTime(offer['endDate'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            offer['offerType'] == 'percentage'
                                ? 'Discount: ${offer['offerValue']}%'
                                : 'Offer Price: ₹${offer['offerValue']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showProductSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Products'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _products.map((product) {
              final name = product['name'] as String;
              final isSelected = _selectedProducts.contains(name);
              return CheckboxListTile(
                title: Text(name),
                subtitle: Text(
                  '₹${product['price']} (MRP: ₹${product['mrp']})',
                ),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedProducts.add(name);
                    } else {
                      _selectedProducts.remove(name);
                    }
                  });
                  Navigator.pop(context);
                  _showProductSearchDialog();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
