import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'shop_products_page.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  Position? _currentPosition;
  String? _currentAddress;
  bool _loading = false;
  bool _locationPermissionGranted = false;
  List<Map<String, dynamic>> _nearbyShops = [];
  bool _loadingShops = false;
  double _searchRadiusKm = 5.0;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Geolocator.checkPermission();
    setState(() {
      _locationPermissionGranted =
          status == LocationPermission.whileInUse ||
          status == LocationPermission.always;
    });
    if (_locationPermissionGranted) {
      await _getCurrentLocation();
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _loading = true);
    try {
      final status = await Geolocator.requestPermission();
      if (status == LocationPermission.whileInUse ||
          status == LocationPermission.always) {
        setState(() => _locationPermissionGranted = true);
        await _getCurrentLocation();
      } else if (status == LocationPermission.deniedForever) {
        // Open app settings if permission is denied forever
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission denied. Please enable it in app settings.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error requesting location permission: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);

      // Get address from coordinates
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          setState(() {
            _currentAddress =
                '${place.street}, ${place.locality}, ${place.postalCode}';
          });
        }
      } catch (e) {
        print('Error getting address: $e');
      }

      // Load nearby shops
      await _loadNearbyShops();
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadNearbyShops() async {
    if (_currentPosition == null) return;

    setState(() => _loadingShops = true);
    try {
      final resp = await http
          .get(Uri.parse('http://localhost:5000/api/Shops'))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final allShops = (data['data'] as List? ?? [])
            .map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s))
            .toList();

        // Filter shops by distance
        final nearby = <Map<String, dynamic>>[];
        for (var shop in allShops) {
          try {
            final lat = shop['latitude'] as double?;
            final lng = shop['longitude'] as double?;

            if (lat != null && lng != null) {
              final distance = _calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                lat,
                lng,
              );

              if (distance <= _searchRadiusKm) {
                shop['distance'] = distance;
                nearby.add(shop);
              }
            }
          } catch (e) {
            print('Error processing shop: $e');
          }
        }

        // Sort by distance
        nearby.sort(
          (a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double),
        );

        setState(() {
          _nearbyShops = nearby;
          _loadingShops = false;
        });
      } else {
        setState(() => _loadingShops = false);
      }
    } catch (e) {
      print('Error loading nearby shops: $e');
      setState(() => _loadingShops = false);
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('location'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Location Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (!_locationPermissionGranted)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enable location to find nearby shops',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loading
                                ? null
                                : _requestLocationPermission,
                            icon: const Icon(Icons.location_on),
                            label: const Text('Enable Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_currentAddress != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.deepOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentAddress!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_currentPosition != null)
                          Text(
                            'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Unable to fetch location',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Search Radius Slider
          if (_locationPermissionGranted && _currentPosition != null) ...[
            const Text(
              'Search Radius',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_searchRadiusKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _searchRadiusKm,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      onChanged: (value) {
                        setState(() => _searchRadiusKm = value);
                        _loadNearbyShops();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Near Me Shops Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Shops',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (_nearbyShops.isNotEmpty)
                Text(
                  '${_nearbyShops.length} found',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_locationPermissionGranted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Center(
                child: Text(
                  'Enable location to see nearby shops',
                  style: TextStyle(fontSize: 14, color: Colors.orange),
                ),
              ),
            )
          else if (_loadingShops)
            const Center(child: CircularProgressIndicator())
          else if (_nearbyShops.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No shops found nearby',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nearbyShops.length,
              itemBuilder: (context, index) {
                final shop = _nearbyShops[index];
                final name = (shop['shopName'] ?? shop['name'] ?? 'Shop')
                    .toString();
                final icon = shop['icon'] ?? '🏪';
                final distance =
                    (shop['distance'] as double?)?.toStringAsFixed(2) ?? '?';
                final rating = (shop['rating'] ?? 0).toString();
                final productCount = shop['productCount'] ?? 0;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopProductsPage(shop: shop),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(
                            icon.toString(),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$productCount products',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$distance km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepOrange.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
