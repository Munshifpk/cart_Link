import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bottom bar/home-shops.dart';
import '../services/auth_state.dart';
// import 'package:cart_link/Admin/shops_admin.dart';
import 'signUp-Shops.dart';
import 'package:cart_link/constant.dart';

// Base auth endpoint for shops.
String get _backendUrl => backendUrl(kApiAuth);

class ShopLoginPage extends StatefulWidget {
  const ShopLoginPage({super.key});

  @override
  State<ShopLoginPage> createState() => _ShopLoginPageState();
}

class _ShopLoginPageState extends State<ShopLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final mobile = _mobileController.text.trim();
      final password = _passwordController.text.trim();

      print('🔍 Verifying credentials for mobile: $mobile');
      print('📡 Connecting to: $_backendUrl/verify-credentials');

      final response = await http
          .post(
            Uri.parse('$_backendUrl/verify-credentials'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'mobile': mobile, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ Login successful');

          final token = data['token'];
          final owner = data['owner'];

          // Save owner into AuthState and persistent storage
          try {
            final ownerMap = owner is Map<String, dynamic>
                ? owner
                : Map<String, dynamic>.from(owner as Map);
            
            // Save to persistent storage with token
            if (token != null) {
              await AuthState.setOwner(ownerMap, token: token);
            } else {
              await AuthState.setOwner(ownerMap);
            }
          } catch (e) {
            print('Error saving shop session: $e');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome back, ${owner['shopName']}!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ShopHomePage()),
                  (Route<dynamic> route) => false,
                );
              }
            });
          }
        } else {
          _showErrorDialog(
            'Login Failed',
            data['message'] ?? 'Invalid credentials',
          );
        }
      } else if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        _showErrorDialog(
          '❌ Authentication Error',
          data['message'] ?? 'Invalid password',
        );
      } else if (response.statusCode == 404) {
        final data = jsonDecode(response.body);
        _showErrorDialog(
          '❌ Account Not Found',
          data['message'] ?? 'No account exists for this mobile number',
        );
      } else {
        _showErrorDialog('Server Error', 'Error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      _showErrorDialog(
        'Connection Error',
        'Failed to connect to backend:\n$e\n\nMake sure backend is running on $backendBaseUrl',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Login'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color.fromARGB(255, 176, 179, 175),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 26,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 41, 96, 179),
                              Color.fromARGB(255, 87, 138, 188),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.storefront_outlined,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Grow your business\nReach more customers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              maxLength: 15,
                              decoration: const InputDecoration(
                                labelText: 'Mobile number',
                                hintText: 'e.g. 9744884713',
                                prefixIcon: Icon(Icons.phone_android_outlined),
                                counterText: '',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter mobile number';
                                }
                                if (v.trim().length < 7) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter password';
                                }
                                if (v.length < 6) return 'Password too short';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    22,
                                    84,
                                    177,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _loading ? null : _verifyCredentials,
                                child: _loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account??",
                            style: TextStyle(color: Colors.black87),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ShopSignUpPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Create one',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join thousands of businesses using our platform to increase sales and reach new customers.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
