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
      // First try Google Places API Autocomplete
      final String googleApiKey = 'AIzaSyBU7H_NkKxBGbVnDBuuu2Cye-H1hhREUvE';
        // Prefer city/region suggestions to improve accuracy for locality searches
        final String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=$query'
          '&key=$googleApiKey'
          '&components=country:in'
          '&language=en'
          '&types=(cities)'
          '&sessiontoken=cart_link_session';

      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final status = data['status'] ?? '';

        // Check if we got valid predictions
        if (status == 'OK') {
          final predictions = (data['predictions'] as List? ?? []);
          final suggestions = <Map<String, String>>[];

          for (var prediction in predictions.take(8)) {
            final placeId = prediction['place_id'] ?? '';
            final description = prediction['description'] ?? '';
            final mainText = prediction['main_text'] ?? '';
            final secondaryText = prediction['secondary_text'] ?? '';

            if (placeId.isNotEmpty) {
              try {
                final detailsUrl =
                    'https://maps.googleapis.com/maps/api/place/details/json'
                    '?place_id=$placeId'
                    '&key=$googleApiKey'
                    '&fields=address_components,formatted_address,geometry'
                    '&language=en';

                final detailsResp = await http.get(Uri.parse(detailsUrl)).timeout(const Duration(seconds: 5));

                if (detailsResp.statusCode == 200) {
                  final detailsData = jsonDecode(detailsResp.body);
                  final result = detailsData['result'] as Map<String, dynamic>? ?? {};
                  final addressComponents = (result['address_components'] as List? ?? []);

                  String city = '';
                  String district = '';
                  String state = '';
                  String postcode = '';

                  // Enhanced parsing: prefer locality > postal_town > sublocality > neighborhood
                  // when Google place details are present.

                  // Parse address components - Google provides these more accurately
                  for (var component in addressComponents) {
                    final types = (component['types'] as List? ?? []);
                    final longName = component['long_name'] ?? '';

                    // Locality is the city/town level
                    if (types.contains('locality')) {
                      city = longName;
                    }
                    if (types.contains('postal_town') && city.isEmpty) {
                      city = longName;
                    }
                    if ((types.contains('sublocality') || types.contains('sublocality_level_1')) && city.isEmpty) {
                      city = longName;
                    }
                    if (types.contains('neighborhood') && city.isEmpty) {
                      city = longName;
                    }
                    // administrative_area_level_3 is often district in India
                    if (types.contains('administrative_area_level_3')) {
                      district = longName;
                    }
                    // administrative_area_level_2 is also sometimes district
                    if (types.contains('administrative_area_level_2') && district.isEmpty) {
                      district = longName;
                    }
                    // administrative_area_level_1 is state
                    if (types.contains('administrative_area_level_1')) {
                      state = longName;
                    }
                    // postal_code for pincode
                    if (types.contains('postal_code')) {
                      postcode = longName;
                    }
                  }

                    // If city is empty, use main_text from prediction or formatted_address
                    if (city.isEmpty) {
                      city = mainText;
                    }
                  // If still no district, try to extract from secondary_text
                  if (district.isEmpty && secondaryText.isNotEmpty) {
                    final parts = secondaryText.split(',');
                    if (parts.isNotEmpty) {
                      // sometimes secondary_text contains "Ernad, Kerala" etc.
                      district = parts[0].trim();
                    }
                  }

                  // If district is still empty (or possibly ambiguous), try reverse geocoding
                  // using Nominatim with the place's lat/lng — its `county` field is often
                  // the proper district name for Indian locations (e.g. Malappuram).
                  try {
                    final geometry = (result['geometry'] ?? {})['location'] as Map<String, dynamic>?;
                    if ((district.isEmpty) && geometry != null) {
                      final lat = geometry['lat'];
                      final lng = geometry['lng'];
                      if (lat != null && lng != null) {
                        final nomUrl = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=10&addressdetails=1';
                        final nomResp = await http.get(Uri.parse(nomUrl)).timeout(const Duration(seconds: 5));
                        if (nomResp.statusCode == 200) {
                          final nomData = jsonDecode(nomResp.body) as Map<String, dynamic>? ?? {};
                          final nomAddress = nomData['address'] as Map<String, dynamic>? ?? {};
                                final nomDistrict = nomAddress['county'] ?? nomAddress['district'] ?? nomAddress['region'] ?? '';
                          if (nomDistrict != null && nomDistrict.toString().isNotEmpty) {
                            district = nomDistrict.toString();
                          }
                        }
                      }
                    }
                  } catch (e) {
                    // ignore reverse geocode errors — we'll use whatever Google returned
                  }

                  // use district as returned by APIs

                  final locationDisplay = _buildLocationDisplay(city, district, state, 'India', postcode);

                  suggestions.add({
                    'name': description,
                    'city': city,
                    'district': district,
                    'state': state,
                    'country': 'India',
                    'postcode': postcode,
                    'display': locationDisplay['full'] ?? description,
                  });
                }
              } catch (e) {
                print('Error fetching place details: $e');
              }
            }
          }

          if (suggestions.isNotEmpty) {
            setState(() => _locationSuggestions = suggestions);
            return;
          }
        }
      }

      // Fallback to Nominatim if Google fails or returns no results
      _searchLocationsNominatim(query);
    } catch (e) {
      print('Error searching locations: $e');
      _searchLocationsNominatim(query);
    }
  }

  Future<void> _searchLocationsNominatim(String query) async {
    try {
      final resp = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&countrycodes=in&limit=8&addressdetails=1',
        ),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        final suggestions = data
            .map<Map<String, String>>((item) {
              final address = item['address'] as Map<String, dynamic>? ?? {};
              final name = item['name'] ?? '';
              final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
              var district = address['county'] ?? '';
              final state = address['state'] ?? '';
              final postcode = address['postcode'] ?? '';

              final locationDisplay = _buildLocationDisplay(city, district, state, 'India', postcode);

              return {
                'name': name.toString(),
                'city': city.toString(),
                'district': district.toString(),
                'state': state.toString(),
                'country': 'India',
                'postcode': postcode.toString(),
                'display': locationDisplay['full'] ?? '',
              };
            })
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

  @override
  void initState() {
    super.initState();
    _suggestions = widget.initialSuggestions;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.location_on, color: ThemeColors.primary),
          const SizedBox(width: 8),
          const Text('Select Location'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.locationController,
              decoration: InputDecoration(
                hintText: 'Search location or pincode',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ThemeColors.primary, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ThemeColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: Icon(Icons.search, color: ThemeColors.primary),
                suffixIcon: widget.locationController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: ThemeColors.primary),
                        onPressed: () {
                          widget.locationController.clear();
                          setState(() => _suggestions = []);
                        },
                      )
                    : null,
              ),
              onChanged: (value) async {
                setState(() {});
                if (value.isNotEmpty) {
                  await widget.searchLocations(value);
                  // Get updated suggestions from parent
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (mounted) {
                    setState(() {
                      _suggestions = widget.getCurrentSuggestions();
                    });
                  }
                } else {
                  setState(() => _suggestions = []);
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.primary,
                foregroundColor: Colors.white,
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
                    setState(() {});
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
            ),
            const SizedBox(height: 12),
            if (_suggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    final display = suggestion['display'] ?? '';
                    final postcode = suggestion['postcode'] ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        dense: false,
                        leading: Icon(Icons.location_on, color: ThemeColors.primary),
                        title: Text(
                          display.isNotEmpty ? display : (suggestion['name'] ?? ''),
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (postcode.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ThemeColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Pincode: $postcode',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: ThemeColors.primary,
                                  ),
                                ),
                              ),
                            if (suggestion['district']?.isNotEmpty ?? false)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'District: ${suggestion['district']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          widget.onLocationSelected(
                            display.isNotEmpty ? display : (suggestion['name'] ?? ''),
                            postcode,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: ThemeColors.primary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeColors.primary,
          ),
          onPressed: () {
            widget.onSave(widget.locationController.text);
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
// class _HomePage extends StatelessWidget {
//   const _HomePage();

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       key: const PageStorageKey('home'),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Welcome back!',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             height: 140,
//             decoration: BoxDecoration(
//               color: Colors.blue.shade100,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Center(child: Text('Promo banner / carousel')),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Recommended',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 8),
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//               childAspectRatio: 3 / 2,
//             ),
//             itemCount: 4,
//             itemBuilder: (context, i) => Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade200,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Center(child: Text('Item ${i + 1}')),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ProductsPage extends StatelessWidget {
//   const _ProductsPage();

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       key: const PageStorageKey('category'),
//       padding: const EdgeInsets.all(16),
//       children: List.generate(
//         8,
//         (i) => Card(
//           child: ListTile(
//             leading: CircleAvatar(child: Text('${i + 1}')),
//             title: Text('Category ${i + 1}'),
//             subtitle: const Text('Tap to view'),
//             onTap: () {},
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _CartPage extends StatelessWidget {
//   const _CartPage();

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       key: const PageStorageKey('cart'),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(
//             Icons.shopping_cart_outlined,
//             size: 64,
//             color: Colors.grey,
//           ),
//           const SizedBox(height: 12),
//           const Text('Your cart is empty', style: TextStyle(fontSize: 16)),
//           const SizedBox(height: 8),
//           ElevatedButton(onPressed: () => {}, child: const Text('Shop now')),
//         ],
//       ),
//     );
//   }
// }

// class _ProfilePage extends StatelessWidget {
//   const _ProfilePage();

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       key: const PageStorageKey('profile'),
//       padding: const EdgeInsets.all(16),
//       children: [
//         const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 48)),
//         const SizedBox(height: 12),
//         const Center(
//           child: Text(
//             'John Doe',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//         ),
//         const SizedBox(height: 24),
//         Card(
//           child: ListTile(
//             title: const Text('Orders'),
//             leading: const Icon(Icons.list),
//             onTap: () {},
//           ),
//         ),
//         Card(
//           child: ListTile(
//             title: const Text('Settings'),
//             leading: const Icon(Icons.settings),
//             onTap: () {},
//           ),
//         ),
//         Card(
//           child: ListTile(
//             title: const Text('Logout'),
//             leading: const Icon(Icons.logout),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => HomePage()),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
