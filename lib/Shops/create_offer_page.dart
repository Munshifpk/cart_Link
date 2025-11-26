import 'package:flutter/material.dart';

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProduct;
  final List<String> _products = [
    'Wireless Headphones',
    'Bluetooth Speaker',
    'Phone Case',
    'Laptop Stand',
  ];
  final TextEditingController _offerPriceController = TextEditingController();
  DateTimeRange? _duration;

  @override
  void dispose() {
    _offerPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickDuration() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange:
          _duration ??
          DateTimeRange(start: now, end: now.add(const Duration(days: 7))),
    );
    if (picked != null) setState(() => _duration = picked);
  }

  void _applyOffer() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }
    if (_duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select offer duration')),
      );
      return;
    }

    // In a real app, call backend to save offer for the product.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Offer applied to $_selectedProduct')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Offer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Product',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedProduct,
                items: _products
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedProduct = v),
                validator: (v) => v == null ? 'Please choose a product' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Offer Price',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _offerPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter offer price';
                  final n = double.tryParse(v);
                  if (n == null) return 'Enter valid number';
                  if (n <= 0) return 'Price must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Duration',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _duration == null
                          ? 'No duration selected'
                          : '${_duration!.start.toLocal().toString().split(' ')[0]} - ${_duration!.end.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _pickDuration,
                    child: const Text('Pick'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyOffer,
                      child: const Text('Apply Offer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
