import 'package:cart_link/Customer/customer_home.dart';
import 'package:cart_link/services/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cart_link/Customer/singup.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// import '../services/customer_service.dart';

final _backendUrl = kIsWeb
    ? 'http://localhost:5000/api/customersauth'
    : 'http://10.0.2.2:5000/api/customersauth';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

          // final token = data['token'];
          final customer = data['owner'];
          try {
            if (customer is Map<String, dynamic>) {
              AuthState.setCustomer(customer);
            } else if (customer is Map) {
              AuthState.setCustomer(Map<String, dynamic>.from(customer));
            }
          } catch (_) {}
          // print('data : $data');
          // print(  '👤 Customer data: $customer');

          if (mounted) {
            // print('load home');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome back, ${customer['customerName']}!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => CustomerHome(
                      customer: Customer(
                        id: customer['_id']?.toString(),
                        customerName: customer['customerName'] ?? '',
                        email: customer['email'],
                        mobile: customer['mobile'] is int
                            ? customer['mobile']
                            : (int.tryParse(
                                customer['mobile']?.toString() ?? '',
                              )),
                        address: customer['address'],
                        createdAt: customer['createdAt'] != null
                            ? DateTime.tryParse(customer['createdAt'])
                            : null,
                      ),
                    ),
                  ),
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
        'Failed to connect to backend:\n$e\n\nMake sure backend is running on http://localhost:5000',
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
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // void _onLogin() {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     // Replace with real auth logic
  //     _showMessage('Logging in ${_mobileController.text}');
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => const CustomerHome()),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Welcome Back!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Login to continue shopping',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        _buildTextFormField(
                          controller: _mobileController,
                          labelText: 'Mobile number',
                          prefixIcon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length != 10) {
                              return 'Phone number must be 10 digits long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _passwordController,
                          labelText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter password';
                            }
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                _showMessage('Forgot password tapped'),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: const Color(0xFFFFA500),
                            foregroundColor: Colors.white,
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpPage(),
                                    ),
                                  ),
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}
