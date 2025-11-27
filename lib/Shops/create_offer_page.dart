import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/auth_state.dart';

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _ProductSearchDelegate extends SearchDelegate<String?> {
  final List<Map<String, dynamic>> products;

  _ProductSearchDelegate(this.products)
    : super(searchFieldLabel: 'Search products');

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  List<Map<String, dynamic>> _searchMatches() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _searchMatches();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final p = results[index];
        return ListTile(
          leading: Text(p['icon'] ?? '', style: const TextStyle(fontSize: 20)),
          title: Text(p['name'] ?? ''),
          subtitle: Text('₹${p['price'] ?? ''}'),
          onTap: () => close(context, p['name'] as String?),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _searchMatches().take(8).toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final p = suggestions[index];
        return ListTile(
          leading: Text(p['icon'] ?? '', style: const TextStyle(fontSize: 20)),
          title: Text(p['name'] ?? ''),
          subtitle: Text('₹${p['price'] ?? ''}'),
          onTap: () => close(context, p['name'] as String?),
        );
      },
    );
  }
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final _formKey = GlobalKey<FormState>();
  // Allow selecting particular products (multi-select)
  final Set<String> _selectedProducts = {};
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _selectedProductSearchController =
      TextEditingController();
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = false;

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
      final fetchedProducts = (result['data'] as List)
          .map(
            (p) => {
              'name': p['name'] ?? 'Unknown',
              'price': p['price'] ?? 0,
              'mrp': p['mrp'] ?? p['price'] ?? 0,
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
    _productController.dispose();
    _priceController.dispose();
    _startController.dispose();
    _endController.dispose();
    _selectedProductSearchController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime({required DateTime initial}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await _pickDateTime(initial: _startDateTime ?? now);
    if (picked == null) return;
    setState(() {
      _startDateTime = picked;
      _startController.text = _formatDateTime(picked);
    });
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now().add(const Duration(days: 1));
    final picked = await _pickDateTime(initial: _endDateTime ?? now);
    if (picked == null) return;
    setState(() {
      _endDateTime = picked;
      _endController.text = _formatDateTime(picked);
    });
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.toIso8601String().split('T').first} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one product')),
      );
      return;
    }
    if (_startDateTime == null || _endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select start and end date/time')),
      );
      return;
    }
    if (!_startDateTime!.isBefore(_endDateTime!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Start must be before end')));
      return;
    }
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid offer price')));
      return;
    }

    // In a real app: call backend to persist offer for selected products.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Offer applied to ${_selectedProducts.length} product(s)',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Offer'),
        actions: [
          IconButton(
            tooltip: 'Search products',
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch<String?>(
                context: context,
                delegate: _ProductSearchDelegate(_products),
              );
              if (result != null && result.isNotEmpty) {
                final found = _products.firstWhere(
                  (p) => (p['name'] ?? '') == result,
                  orElse: () => {},
                );
                if (found.isNotEmpty) {
                  setState(() {
                    _productController.text = found['name'] ?? '';
                    _priceController.text = (found['price'] ?? '').toString();
                  });
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Product (name)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _productController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (v) {
                  if ((v == null || v.isEmpty) && _selectedProducts.isEmpty) {
                    return 'Enter product or add via search';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              if (_selectedProducts.isNotEmpty) ...[
                TextField(
                  controller: _selectedProductSearchController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Headphones, Speaker',
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
                  'Filtered: ${_selectedProducts.where((p) => p.toLowerCase().contains(_selectedProductSearchController.text.toLowerCase().trim())).length} of ${_selectedProducts.length} selected',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _selectedProducts
                      .where(
                        (name) => name.toLowerCase().contains(
                          _selectedProductSearchController.text
                              .toLowerCase()
                              .trim(),
                        ),
                      )
                      .map((name) {
                        return Chip(
                          label: Text(name),
                          onDeleted: () =>
                              setState(() => _selectedProducts.remove(name)),
                        );
                      })
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
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
                  if (double.tryParse(v) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text('Start (date & time)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _startController,
                readOnly: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onTap: _pickStart,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select start' : null,
              ),
              const SizedBox(height: 12),
              const Text('End (date & time)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _endController,
                readOnly: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onTap: _pickEnd,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select end' : null,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _apply,
                      child: const Text('Create Offer'),
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
