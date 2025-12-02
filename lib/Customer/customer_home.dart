import 'package:flutter/material.dart';
import 'bottom bar/home_page.dart';
import 'bottom bar/products_page.dart';
import 'bottom bar/cart_page.dart';
import 'bottom bar/profile_page.dart';
import '../theme_data.dart';
import 'package:cart_link/shared/notification_actions.dart';
import 'bottom bar/shops_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Google Maps API key must be provided at build/run time using --dart-define
// Example: flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
const String kGoogleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

/// Map of known villages/towns to their correct districts
/// Useful for rural areas where geocoding data is incomplete (works across India)
const Map<String, String> kVillageDistrictMap = {
  'chattiparambu': 'Malappuram',
  'ernad': 'Malappuram',
  'kunnamkulam': 'Thrissur',
  'taliparamba': 'Kannur',
  'kottapuram': 'Thrissur',
  'ottapalam': 'Palakkad',
  'kodungalloor': 'Ernakulam',
  'payyannur': 'Kannur',
  'neendakara': 'Kollam',
  'kilimanoor': 'Thiruvananthapuram',
  'chathannoor': 'Kollam',
  'alappuzha': 'Alappuzha',
  'changanacherry': 'Kottayam',
};

/// Get district for a place name using village mapping (case-insensitive)
String _getDistrictFromVillageMap(String placeName) {
  final nameLower = placeName.toLowerCase().trim();
  return kVillageDistrictMap[nameLower] ?? '';
}

class Customer {
  final String? id;
  final String customerName;
  final String? email;
  final int? mobile;
  final String? address;
  final DateTime? createdAt;

  const Customer({
    this.id,
    required this.customerName,
    this.email,
    this.mobile,
    this.address,
    this.createdAt,
  });
}

class CustomerHome extends StatefulWidget {
  final Customer customer;
  const CustomerHome({super.key, required this.customer});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentIndex = 0;
  String _selectedLocation = 'Select Location';
  String _selectedPincode = '';
  List<Map<String, String>> _locationSuggestions = [];

  List<Widget> get _pages => <Widget>[
    CustomerHomePage(customer: widget.customer),
    const ShopsPage(),
    CustomerProductsPage(),
    CustomerCartPage(customer: widget.customer),
    CustomerProfilePage(customer: widget.customer),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _getLocationFromCoordinates(double lat, double lng) async {
    try {
      // Using nominatim (OpenStreetMap) for reverse geocoding
      final resp = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};
        
        final city = address['city'] ?? address['town'] ?? address['village'] ?? 'Unknown';
        final district = address['county'] ?? '';
        final state = address['state'] ?? '';
        final country = address['country'] ?? '';
        final postcode = address['postcode'] ?? '';
        
        final locationDisplay = _buildLocationDisplay(city, district, state, country, postcode);
        
        setState(() {
          _selectedLocation = locationDisplay['full'] ?? '';
          _selectedPincode = postcode.toString();
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Map<String, String> _buildLocationDisplay(dynamic city, dynamic district, dynamic state, dynamic country, dynamic postcode) {
    final cityStr = city?.toString() ?? '';
    final districtStr = district?.toString() ?? '';
    final stateStr = state?.toString() ?? '';
    final countryStr = country?.toString() ?? '';
    final pincodeStr = postcode?.toString() ?? '';
    
    final parts = <String>[];
    if (cityStr.isNotEmpty) parts.add(cityStr);
    if (districtStr.isNotEmpty && districtStr != cityStr) parts.add(districtStr);
    if (stateStr.isNotEmpty) parts.add(stateStr);
    if (countryStr.isNotEmpty) parts.add(countryStr);
    
    return {
      'city': cityStr,
      'district': districtStr,
      'state': stateStr,
      'country': countryStr,
      'pincode': pincodeStr,
      'full': parts.join(', '),
    };
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() => _locationSuggestions = []);
      return;
    }

    try {
      // First try Google Places API Autocomplete if key provided
      if (kGoogleMapsApiKey.isEmpty) {
        // No API key provided; fall back to Nominatim search only
        _searchLocationsNominatim(query);
        return;
      }
      
      // Encode query for API
      final encoded = Uri.encodeQueryComponent(query);
      final String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=$encoded'
          '&key=$kGoogleMapsApiKey'
          '&language=en'
          '&sessiontoken=cart_link_session';

      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final status = data['status'] ?? '';

        // Check if we got valid predictions
        if (status == 'OK') {
          final predictions = (data['predictions'] as List? ?? []);

          // Build quick suggestions from predictions - show ALL results, no filtering
          final suggestions = predictions
              .take(12)
              .map<Map<String, String>>((prediction) {
            final placeId = prediction['place_id'] ?? '';
            final description = prediction['description'] ?? '';
            final mainText = prediction['structured_formatting']?['main_text'] ?? '';
            return {
              'place_id': placeId.toString(),
              'name': description.toString(),
              'display': description.toString(),
              'city': mainText.toString(),
              'district': '',
              'state': '',
              'postcode': '',
              'latitude': '',
              'longitude': '',
              'formatted_address': '',
            };
          }).toList();

          // show quick suggestions immediately - no wait for details
          setState(() => _locationSuggestions = suggestions.cast<Map<String, String>>());

          // fetch details asynchronously for top predictions (limit to 8)
          // This happens in background without blocking UI
          final detailFutures = predictions.take(8).map((prediction) async {
            try {
              final placeId = prediction['place_id'] ?? '';
              if (placeId.isEmpty) return;
              
              final detailsUrl =
                  'https://maps.googleapis.com/maps/api/place/details/json'
                  '?place_id=${Uri.encodeQueryComponent(placeId)}'
                  '&key=$kGoogleMapsApiKey'
                  '&fields=address_components,formatted_address,geometry'
                  '&language=en';

              final detailsResp = await http.get(Uri.parse(detailsUrl)).timeout(const Duration(seconds: 5));
              if (detailsResp.statusCode != 200) return;

              final detailsData = jsonDecode(detailsResp.body);
              final result = detailsData['result'] as Map<String, dynamic>? ?? {};
              final addressComponents = (result['address_components'] as List? ?? []);
              final formattedAddress = result['formatted_address'] ?? '';
              final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
              final location = geometry['location'] as Map<String, dynamic>? ?? {};

              String city = '';
              String district = '';
              String state = '';
              String postcode = '';
              double latitude = 0;
              double longitude = 0;

              if (location.isNotEmpty) {
                latitude = location['lat'] ?? 0.0;
                longitude = location['lng'] ?? 0.0;
              }

              for (var component in addressComponents) {
                final types = (component['types'] as List? ?? []);
                final longName = component['long_name'] ?? '';
                if (types.contains('locality')) city = longName;
                if (types.contains('postal_town') && city.isEmpty) city = longName;
                if ((types.contains('sublocality') || types.contains('sublocality_level_1')) && city.isEmpty) city = longName;
                if (types.contains('administrative_area_level_3')) district = longName;
                if (types.contains('administrative_area_level_2') && district.isEmpty) district = longName;
                if (types.contains('administrative_area_level_1')) state = longName;
                if (types.contains('postal_code')) postcode = longName;
              }

              // Try to extract district if still empty
              if (district.isEmpty || district.length > 30) {
                final mappedDistrict = _getDistrictFromVillageMap(city);
                if (mappedDistrict.isNotEmpty) {
                  district = mappedDistrict;
                }
              }

              // Update the suggestion entry matching this place_id
              if (mounted) {
                setState(() {
                  for (var s in _locationSuggestions) {
                    if (s['place_id'] == placeId) {
                      s['city'] = city;
                      s['district'] = district;
                      s['state'] = state;
                      s['postcode'] = postcode;
                      s['latitude'] = latitude.toString();
                      s['longitude'] = longitude.toString();
                      s['formatted_address'] = formattedAddress;
                      break;
                    }
                  }
                });
              }
            } catch (e) {
              // ignore individual detail failures
            }
          }).toList();

          // fire-and-forget details fetching
          Future.wait(detailFutures);
          return;
        }
      }

      // Fallback to Nominatim if Google fails
      _searchLocationsNominatim(query);
    } catch (e) {
      print('Error searching locations: $e');
      _searchLocationsNominatim(query);
    }
  }

  Future<void> _searchLocationsNominatim(String query) async {
    if (query.isEmpty) {
      setState(() => _locationSuggestions = []);
      return;
    }

    try {
      // Use Nominatim OpenStreetMap API as fallback - search all India, no restrictions
      final encoded = Uri.encodeQueryComponent(query);
      final resp = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$encoded&countrycodes=in&limit=25&addressdetails=1',
        ),
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        final queryLower = query.toLowerCase();
        
        final suggestions = data
            .where((item) {
              // Filter: match query text, no geographic restrictions
              final address = item['address'] as Map<String, dynamic>? ?? {};
              final displayName = (item['display_name'] ?? '').toString().toLowerCase();
              
              return displayName.contains(queryLower);
            })
            .map<Map<String, String>>((item) {
              final address = item['address'] as Map<String, dynamic>? ?? {};
              final displayName = item['display_name'] ?? '';
              final name = item['name'] ?? '';
              final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
              final district = address['district'] ?? address['county'] ?? address['administrative_area_level_2'] ?? address['administrative_area_level_3'] ?? '';
              final state = address['state'] ?? '';
              final postcode = address['postcode'] ?? '';
              final lat = item['lat'] ?? '0';
              final lon = item['lon'] ?? '0';

              return {
                'place_id': item['place_id']?.toString() ?? '',
                'name': displayName.toString(),
                'display': displayName.toString(),
                'city': city.toString(),
                'district': district.toString(),
                'state': state.toString(),
                'postcode': postcode.toString(),
                'latitude': lat.toString(),
                'longitude': lon.toString(),
                'formatted_address': displayName.toString(),
              };
            })
            .toList()
            .take(12)
            .toList();

        setState(() => _locationSuggestions = suggestions);
      }
    } catch (e) {
      print('Error with Nominatim fallback: $e');
    }
  }

  Future<void> _showLocationPicker() async {
    final TextEditingController locationController = TextEditingController(text: _selectedLocation == 'Select Location' ? '' : _selectedLocation);
    
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _LocationPickerDialog(
        locationController: locationController,
        initialSuggestions: _locationSuggestions,
        onLocationSelected: (location, pincode) {
          setState(() {
            _selectedLocation = location;
            _selectedPincode = pincode;
          });
          Navigator.pop(dialogContext);
        },
        onSave: (location) {
          setState(() {
            _selectedLocation = location.isNotEmpty ? location : 'Select Location';
          });
          Navigator.pop(dialogContext);
        },
        onGetCurrentLocation: (lat, lng) async {
          await _getLocationFromCoordinates(lat, lng);
          if (mounted) {
            locationController.text = _selectedLocation;
          }
        },
        searchLocations: (query) async {
          await _searchLocations(query);
        },
        getCurrentSuggestions: () => _locationSuggestions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.location_on, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _showLocationPicker,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      _selectedLocation,
                      style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedPincode.isNotEmpty)
                      Text(
                        _selectedPincode,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeColors.primary,
        foregroundColor: ThemeColors.textColorWhite,
        toolbarHeight: 72,
        centerTitle: false,
        elevation: 2,
      ),

      // Move previous "app bar" elements here, below the AppBar
      body: Column(
        children: [
          // top controls (search, notifications)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Search bar (expanded centered)
                  Expanded(
                    child: Center(
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Search for products, brands...',
                                ),
                                onSubmitted: (q) {
                                  // TODO: perform search
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Notification / updates actions (top right)
                  const NotificationActions(),
                ],
              ),
            ),
          ),

          // Main pages area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                final inAnim = Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: inAnim, child: child),
                );
              },
              child: SizedBox(
                key: ValueKey<int>(_currentIndex),
                width: double.infinity,
                height: double.infinity,
                child: _pages[_currentIndex],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shops'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_sharp),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _LocationPickerDialog extends StatefulWidget {
  final TextEditingController locationController;
  final List<Map<String, String>> initialSuggestions;
  final Function(String location, String pincode) onLocationSelected;
  final Function(String location) onSave;
  final Function(double lat, double lng) onGetCurrentLocation;
  final Function(String query) searchLocations;
  final List<Map<String, String>> Function() getCurrentSuggestions;

  const _LocationPickerDialog({
    required this.locationController,
    required this.initialSuggestions,
    required this.onLocationSelected,
    required this.onSave,
    required this.onGetCurrentLocation,
    required this.searchLocations,
    required this.getCurrentSuggestions,
  });

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  late List<Map<String, String>> _suggestions;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _suggestions = widget.initialSuggestions;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: ThemeColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            // Search input section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 12,
                children: [
                  // Search field
                  TextField(
                    controller: widget.locationController,
                    decoration: InputDecoration(
                      hintText: 'Search city, area, or address...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ThemeColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      prefixIcon: Icon(Icons.search, color: ThemeColors.primary, size: 22),
                      suffixIcon: widget.locationController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[600]),
                              onPressed: () {
                                widget.locationController.clear();
                                setState(() => _suggestions = []);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      setState(() {});
                      // Debounce with shorter delay for snappier response
                      _debounce?.cancel();
                      if (value.isEmpty) {
                        setState(() => _suggestions = []);
                        return;
                      }
                      _debounce = Timer(const Duration(milliseconds: 150), () async {
                        try {
                          await widget.searchLocations(value);
                          if (!mounted) return;
                          setState(() {
                            _suggestions = widget.getCurrentSuggestions();
                          });
                        } catch (_) {}
                      });
                    },
                  ),
                  
                  // Current location button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColors.primary.withOpacity(0.15),
                        foregroundColor: ThemeColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        try {
                          final permission = await Geolocator.requestPermission();
                          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Location permission denied')),
                              );
                            }
                            return;
                          }

                          final position = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high,
                          );

                          await widget.onGetCurrentLocation(position.latitude, position.longitude);
                          if (mounted) {
                            setState(() {
                              widget.locationController.text = '';
                              _suggestions = [];
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.my_location, size: 20),
                      label: const Text('Use Current Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
            
            // Suggestions list
            if (_suggestions.isEmpty && widget.locationController.text.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No locations found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Try searching with different keywords',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else if (_suggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    final display = suggestion['display'] ?? '';
                    final name = suggestion['name'] ?? '';
                    final postcode = suggestion['postcode'] ?? '';
                    final district = suggestion['district'] ?? '';
                    final city = suggestion['city'] ?? '';
                    final state = suggestion['state'] ?? '';
                    
                    // Build location name (prefer formatted display, fall back to name)
                    final locationName = display.isNotEmpty ? display : name;
                    
                    // Build subtitle with city, district, state
                    final parts = <String>[];
                    if (city.isNotEmpty) parts.add(city);
                    if (district.isNotEmpty && district != city) parts.add(district);
                    if (state.isNotEmpty && state != district) parts.add(state);
                    final subtitle = parts.join(' • ');

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          widget.onLocationSelected(locationName, postcode);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Location pin icon
                              Padding(
                                padding: const EdgeInsets.only(top: 4, right: 12),
                                child: Icon(Icons.location_on, color: ThemeColors.primary, size: 22),
                              ),
                              
                              // Location details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locationName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (subtitle.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          subtitle,
                                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (postcode.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: ThemeColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            postcode,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: ThemeColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Chevron icon
                              Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
