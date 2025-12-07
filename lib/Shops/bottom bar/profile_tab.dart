import 'dart:io';
import 'dart:convert';

import 'package:cart_link/Shops/analytics/analytics_page.dart';
import 'package:cart_link/Shops/daily_sales.dart';
import 'package:cart_link/Shops/report_page.dart';
import 'package:cart_link/main.dart';
import 'package:cart_link/services/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String name = '';
  String email = '';
  String phone = '';
  String shopName = '';
  String address = '';
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  
  String? _shopId;
  int _followersCount = 0;
  bool _loadingShop = true;

  String get _backendBase {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    try {
      final shopId = AuthState.currentOwner?['_id']?.toString();
      print('🔍 Loading shop data for ID: $shopId');
      
      if (shopId == null || shopId.isEmpty) {
        print('❌ No shop ID found in AuthState');
        if (mounted) {
          setState(() => _loadingShop = false);
        }
        return;
      }

      // Fetch shop details directly by ID
      final resp = await http
          .get(Uri.parse('$_backendBase/api/Shops/$shopId'))
          .timeout(const Duration(seconds: 10));
      
      print('📡 Response status: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final shop = data['data'];
        
        print('📦 Shop data: $shop');

        if (shop != null && mounted) {
          _shopId = shop['_id']?.toString();
          final followers = shop['followers'] as List? ?? [];
          
          final loadedShopName = shop['shopName']?.toString() ?? '';
          final loadedAddress = shop['location']?.toString() ?? shop['address']?.toString() ?? '';
          final loadedEmail = shop['email']?.toString() ?? '';
          final loadedPhone = shop['mobile']?.toString() ?? '';
          final loadedName = shop['ownerName']?.toString() ?? '';
          
          print('📱 Loaded phone: $loadedPhone');
          print('📧 Loaded email: $loadedEmail');
          
          setState(() {
            shopName = loadedShopName;
            address = loadedAddress;
            email = loadedEmail;
            phone = loadedPhone;
            name = loadedName;
            _followersCount = followers.length;
            _loadingShop = false;
          });
        } else {
          print('❌ Shop data is null');
          if (mounted) {
            setState(() => _loadingShop = false);
          }
        }
      } else {
        print('❌ Failed to load shop: ${resp.statusCode}');
        if (mounted) {
          setState(() => _loadingShop = false);
        }
      }
    } catch (e) {
      print('❌ Error loading shop data: $e');
      if (mounted) {
        setState(() => _loadingShop = false);
      }
    }
  }

  Future<void> _showFollowersList() async {
    if (_shopId == null || _shopId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop ID not found')),
      );
      return;
    }

    try {
      final resp = await http
          .get(Uri.parse('$_backendBase/api/Shops/$_shopId/followers'))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(resp.body);
        final followers = (data['data']?['followers'] as List? ?? [])
            .map<Map<String, dynamic>>((f) => Map<String, dynamic>.from(f))
            .toList();

        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) {
            if (followers.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('No followers yet')),
              );
            }
            return SizedBox(
              height: 400,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Followers',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: followers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final follower = followers[index];
                        final followerName = follower['customerName']?.toString() ?? 'Customer';
                        final followerEmail = follower['email']?.toString() ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(followerName.isNotEmpty ? followerName[0].toUpperCase() : 'C'),
                          ),
                          title: Text(followerName),
                          subtitle: followerEmail.isNotEmpty ? Text(followerEmail) : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load followers')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading followers: $e')),
        );
      }
    }
  }

  void _openEditDialog() {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);
    final shopController = TextEditingController(text: shopName);
    final addressController = TextEditingController(text: address);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                ),
                TextFormField(
                  controller: shopController,
                  decoration: const InputDecoration(labelText: 'Shop Name'),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() {
                  name = nameController.text.trim();
                  email = emailController.text.trim();
                  phone = phoneController.text.trim();
                  shopName = shopController.text.trim();
                  address = addressController.text.trim();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _profileImage = File(picked.path);
        });
      }
    } catch (e) {
      // ignore errors for now
    }
  }

  void _showImageOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.blueGrey.shade100,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!) as ImageProvider
                          : null,
                      child: _profileImage == null
                          ? const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shopName,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: _openEditDialog,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                _infoTile(Icons.email_outlined, 'Email', email),
                const Divider(height: 1),
                _infoTile(Icons.phone_outlined, 'Phone', phone),
                const Divider(height: 1),
                _infoTile(Icons.location_on_outlined, 'Address', address),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.group, color: Colors.blueGrey),
                  title: const Text('Followers'),
                  subtitle: Text(_loadingShop ? 'Loading...' : '$_followersCount follower(s)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _loadingShop ? null : _showFollowersList,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailySalesPage()),
              );
            },
            icon: const Icon(Icons.trending_up),
            label: const Text('Total Sales'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportPage()),
              );
            },
            icon: const Icon(Icons.flag),
            label: const Text('Reports'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsPage()),
              );
            },
            icon: const Icon(Icons.analytics),
            label: const Text('Analytics'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
