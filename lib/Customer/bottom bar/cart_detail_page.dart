import 'package:flutter/material.dart';

class CartDetailPage extends StatefulWidget {
  final Map<String, dynamic> cart;
  const CartDetailPage({super.key, required this.cart});

  @override
  State<CartDetailPage> createState() => _CartDetailPageState();
}

class _CartDetailPageState extends State<CartDetailPage> {
  late Map<String, dynamic> _cart;

  @override
  void initState() {
    super.initState();
    _cart = Map<String, dynamic>.from(widget.cart);
    _cart['items'] = List<Map<String, dynamic>>.from(_cart['items'] ?? []);
  }

  void _addItem() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '0.00');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
              if (name.isEmpty) return;
              setState(() {
                (_cart['items'] as List).add({
                  'name': name,
                  'qty': qty,
                  'price': price,
                });
              });
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => (_cart['items'] as List).removeAt(index));
  }

  double get _total => (_cart['items'] as List).fold(
    0.0,
    (s, e) => s + (e['qty'] as int) * (e['price'] as double),
  );

  void _saveAndClose() {
    Navigator.of(context).pop(_cart);
  }

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(_cart['items'] as List);

    return Scaffold(
      appBar: AppBar(title: Text('Cart - ${_cart['shop'] ?? ''}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No items in cart'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final it = items[i];
                        return ListTile(
                          title: Text(it['name'] ?? ''),
                          subtitle: Text(
                            'Qty: ${it['qty']}  •  Price: ${it['price']}',
                          ),
                          trailing: IconButton(
                            onPressed: () => _removeItem(i),
                            icon: const Icon(Icons.delete),
                          ),
                        );
                      },
                    ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ' + '\$' + _total.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveAndClose,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
