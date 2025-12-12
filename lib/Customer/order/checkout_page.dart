import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme_data.dart';
import '../../services/order_service.dart';
import '../../services/auth_state.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  final String? shopId; // null means all shops
  final String shopName;
  final List<dynamic>
  items; // list of item maps: {productId, productName, quantity, price, total}

  const CheckoutPage({
    super.key,
    this.shopId,
    required this.shopName,
    required this.items,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _processing = false;
  final TextEditingController _addressCtrl = TextEditingController();
  double? _lat;
  double? _lng;
  static const LatLng _fallbackCenter = LatLng(20.5937, 78.9629); // India centroid fallback

  double _calcTotal() {
    double total = 0.0;
    for (var it in widget.items) {
      total += (it['total'] ?? 0).toDouble();
    }
    return total;
  }

  int _calcItems() {
    int t = 0;
    for (var it in widget.items) {
      t += (it['quantity'] ?? 0) as int;
    }
    return t;
  }

  Future<void> _confirmOrder() async {
    setState(() => _processing = true);

    final customerId = AuthState.currentCustomer?['_id'] ??
        AuthState.currentCustomer?['id'];

    if (customerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Customer not logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _processing = false);
      return;
    }

    // Prepare order data
    // Use the shopId passed to this page
    final shopId = widget.shopId;
    if (shopId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Shop ID is missing'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _processing = false);
      return;
    }

    // Require delivery address
    if (_addressCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your delivery address'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _processing = false);
      return;
    }

    // Build products list for this shop
    final products = widget.items.map((item) => {
      'productId': item['productId'],
      'quantity': item['quantity'] ?? 1,
      'price': item['price'] ?? 0.0,
      'mrp': item['mrp'],
    }).toList();

    // Create order (one customer, one shop)
    final result = await OrderService.createOrder(
      customerId: customerId,
      shopId: shopId,
      products: products,
      deliveryAddress: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
      deliveryLat: _lat,
      deliveryLng: _lng,
    );

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      final orderId = result['data']['_id'] ?? result['data']['id'];
      if (orderId != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessPage(orderId: orderId),
          ),
        );
        // After success page, cart will be refreshed automatically
      }
    } else {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to place order',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _useMyLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw 'Location permission denied. Please grant permission in Settings.';
      }

      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition() ??
            (throw 'Could not get current position');
      }

      _lat = pos.latitude;
      _lng = pos.longitude;

      try {
        final placemarks = await placemarkFromCoordinates(_lat!, _lng!);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final address = [
            p.name,
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.postalCode,
            p.country,
          ].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim()).join(', ');
          setState(() {
            _addressCtrl.text = address.isNotEmpty
                ? address
                : '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}';
          });
        } else {
          setState(() {
            _addressCtrl.text = '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}';
          });
        }
      } catch (geocodeErr) {
        setState(() {
          _addressCtrl.text = '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reverse geocode failed, using coordinates. ($geocodeErr)')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    }
  }

  Future<void> _pickOnMap() async {
    LatLng? chosen;
    final start = (_lat != null && _lng != null)
        ? LatLng(_lat!, _lng!)
        : _fallbackCenter;

    await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: start,
                      zoom: 14,
                    ),
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    onTap: (latLng) {
                      setSheetState(() {
                        chosen = latLng;
                      });
                    },
                    markers: {
                      if (chosen != null)
                        Marker(
                          markerId: const MarkerId('delivery'),
                          position: chosen!,
                          infoWindow: const InfoWindow(title: 'Delivery location'),
                        ),
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      onPressed: chosen == null
                          ? null
                          : () {
                              Navigator.of(context).pop(chosen);
                            },
                      icon: const Icon(Icons.check),
                      label: const Text('Use this location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ).then((value) {
      if (value != null) {
        chosen = value;
      }
    });

    if (chosen != null) {
      _lat = chosen!.latitude;
      _lng = chosen!.longitude;
      try {
        final placemarks = await placemarkFromCoordinates(_lat!, _lng!);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final address = [
            p.name,
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.postalCode,
            p.country,
          ].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim()).join(', ');
          setState(() {
            _addressCtrl.text = address;
          });
        }
      } catch (_) {
        // Keep coords even if reverse geocode fails
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcTotal();
    final totalItems = _calcItems();

    // compute totals based on MRP and selling price
    double subtotal = 0.0; // sum of selling price * qty
    double totalMrp = 0.0; // sum of mrp * qty
    double totalDiscount = 0.0; // sum of (mrp - price) * qty

    for (var raw in widget.items) {
      final it = raw as Map<String, dynamic>;
      final qty = (it['quantity'] ?? 0) is int
          ? (it['quantity'] ?? 0) as int
          : int.tryParse((it['quantity'] ?? '0').toString()) ?? 0;
      final priceRaw =
          it['price'] ?? it['sellingPrice'] ?? it['offerPrice'] ?? 0;
      final mrpRaw = it['mrp'] ?? it['MRP'] ?? it['listingMrp'] ?? priceRaw;
      final price = (priceRaw is num)
          ? priceRaw.toDouble()
          : double.tryParse(priceRaw.toString()) ?? 0.0;
      final mrp = (mrpRaw is num)
          ? mrpRaw.toDouble()
          : double.tryParse(mrpRaw.toString()) ?? price;

      subtotal += price * qty;
      totalMrp += mrp * qty;
      final disc = (mrp - price) > 0 ? (mrp - price) * qty : 0.0;
      totalDiscount += disc;
    }

    final grandTotal = double.parse(subtotal.toStringAsFixed(2));

    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          widget.shopId == null
              ? 'Checkout — All Shops'
              : 'Checkout — ${widget.shopName}',
        ),
        backgroundColor: ThemeColors.primary,
        foregroundColor: ThemeColors.textColorWhite,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                  ThemeColors.primary,
                  ThemeColors.accent.withOpacity(0.9),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalItems item(s)',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Make entire screen scrollable: items + summary + actions
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    // Delivery address and location selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Delivery Details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Address',
                              hintText: 'House/Flat, Street, Area, City',
                              border: OutlineInputBorder(),
                              helperText: 'Required',
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _processing ? null : _useMyLocation,
                                  icon: const Icon(Icons.my_location),
                                  label: const Text('Use my location'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _processing ? null : () {
                                    if (kIsWeb) {
                                      // On web, ensure the Maps JS API is loaded; otherwise show a hint.
                                      _pickOnMap();
                                    } else {
                                      _pickOnMap();
                                    }
                                  },
                                  icon: const Icon(Icons.map),
                                  label: const Text('Pick on map'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.items.isEmpty) ...[
                      const SizedBox(height: 24),
                      const Center(child: Text('No items to checkout')),
                      const SizedBox(height: 24),
                    ] else
                      ...widget.items.map<Widget>((raw) {
                        final it = raw as Map<String, dynamic>;
                        final qty = (it['quantity'] ?? 0) is int
                            ? (it['quantity'] ?? 0) as int
                            : int.tryParse(
                                    (it['quantity'] ?? '0').toString(),
                                  ) ??
                                  0;
                        final priceRaw =
                            it['price'] ??
                            it['sellingPrice'] ??
                            it['offerPrice'] ??
                            0;
                        final mrpRaw =
                            it['mrp'] ??
                            it['MRP'] ??
                            it['listingMrp'] ??
                            priceRaw;
                        final price = (priceRaw is num)
                            ? priceRaw.toDouble()
                            : double.tryParse(priceRaw.toString()) ?? 0.0;
                        final mrp = (mrpRaw is num)
                            ? mrpRaw.toDouble()
                            : double.tryParse(mrpRaw.toString()) ?? price;
                        final lineTotal = price * qty;

                        return Column(
                          children: [
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            it['productName'] ??
                                                it['name'] ??
                                                'Product',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Qty: $qty  •  Price: ₹${price.toStringAsFixed(2)}  •  MRP: ₹${mrp.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          if ((mrp - price) > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Text(
                                                'You save: ₹${((mrp - price) * qty).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${lineTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),

                    // Order summary and actions now scroll with the items
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Visual calculation summary
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Subtotal'),
                                      Text('₹${subtotal.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total MRP'),
                                      Text('₹${totalMrp.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Discount'),
                                      Text(
                                        '-₹${totalDiscount.toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Grand Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '₹${grandTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Address summary directly under Grand Total
                                  if (_addressCtrl.text.trim().isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const Text(
                                          'Deliver To',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.location_on, color: Colors.deepOrange),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(_addressCtrl.text.trim())),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _processing ? null : _confirmOrder,
                            icon: _processing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.payment),
                            label: Text(
                              _processing
                                  ? 'Processing...'
                                  : 'Confirm & Order ₹${grandTotal.toStringAsFixed(2)}',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: ThemeColors.primary,
                              foregroundColor: ThemeColors.textColorWhite,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _processing
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ThemeColors.primary,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }
}
