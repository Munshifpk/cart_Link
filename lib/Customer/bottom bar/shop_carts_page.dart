import 'package:flutter/material.dart';
import 'cart_detail_page.dart';

class ShopCartsPage extends StatefulWidget {
  final String shopName;
  const ShopCartsPage({super.key, required this.shopName});

  @override
  State<ShopCartsPage> createState() => _ShopCartsPageState();
}

class _ShopCartsPageState extends State<ShopCartsPage> {
  // Each cart: { 'id': String, 'name': String, 'items': List<Map> }
  final List<Map<String, dynamic>> _carts = [];

  void _createCart() async {
    if (_carts.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 5 carts per shop')));
      return;
    }

    final nameCtrl = TextEditingController();
    final name = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Cart Name'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Cart name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(nameCtrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        _carts.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': name,
          'items': <Map<String, dynamic>>[],
        });
      });
    }
  }

  void _openCart(int index) async {
    final cart = Map<String, dynamic>.from(_carts[index]);
    cart['shop'] = widget.shopName;
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => CartDetailPage(cart: cart)),
    );
    if (updated != null) {
      setState(() {
        _carts[index] = updated;
        _carts[index].remove('shop');
      });
    }
  }

  void _removeCart(int index) {
    setState(() => _carts.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Carts — ${widget.shopName}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: _carts.isEmpty
                  ? const Center(child: Text('No carts yet. Tap + to add one.'))
                  : ListView.separated(
                      itemCount: _carts.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final c = _carts[i];
                        return ListTile(
                          title: Text(c['name'] ?? 'Cart ${i + 1}'),
                          subtitle: Text(
                            'Items: ${(c['items'] as List).length}',
                          ),
                          onTap: () => _openCart(i),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _removeCart(i),
                          ),
                        );
                      },
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createCart,
                    icon: const Icon(Icons.add),
                    label: const Text('New Cart'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
