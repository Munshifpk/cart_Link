import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bottom bar/home-Shops.dart';
import 'login-Shops.dart';
import '../services/auth_service.dart';

/// Simple AuthService implementation — replace endpoints with your real API.

class ShopSignUpPage extends StatefulWidget {
  const ShopSignUpPage({super.key});

  @override
  State<ShopSignUpPage> createState() => _ShopSignUpPageState();
}

class _ShopSignUpPageState extends State<ShopSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _shopName = TextEditingController();
  final _ownerName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _address = TextEditingController();
  final _taxId = TextEditingController();

  String? _businessType;
  final List<String> _types = [
    'Retail',
    'Grocery',
    'Electronics',
    'Fashion',
    'Food & Beverages',
    'Pharmacy',
    'Others',
  ];

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _mobileVerified = false;
  bool _checkingMobile = false;

  @override
  void dispose() {
    _shopName.dispose();
    _ownerName.dispose();
    _mobile.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _address.dispose();
    _taxId.dispose();
    super.dispose();
  }

  Future<void> _checkMobileAvailability() async {
    final mobileText = _mobile.text.trim();
    if (mobileText.isEmpty || mobileText.length < 7) {
      _showErrorDialog('Invalid Mobile', 'Enter a valid mobile number');
      if (mounted) setState(() => _mobileVerified = false);
      return;
    }

    if (mounted) setState(() => _checkingMobile = true);

    try {
      final dynamic result = await AuthService.checkMobileExists(mobileText);

      if (!mounted) return;

      // Normalize result into a Map-like object safely
      String message = 'This mobile is already registered';
      bool success = false;
      bool exists = true;

      if (result is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(result);
        success = map['success'] == true;
        exists = map['exists'] == true;
        if (map['message'] != null) {
          message = map['message'].toString();
        } else if (map['error'] != null)
          message = map['error'].toString();
        else if (map['msg'] != null)
          message = map['msg'].toString();
      } else if (result is String) {
        message = result;
      } else if (result != null) {
        // Fallback for other types
        message = result.toString();
      }

      if (success && exists == false) {
        if (mounted) setState(() => _mobileVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Mobile number is available'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (mounted) setState(() => _mobileVerified = false);
        _showErrorDialog('Mobile Not Available', message);
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _mobileVerified = false);
      _showErrorDialog('Timeout', 'Request timed out. Try again.');
    } catch (e, s) {
      debugPrint('checkMobile error: $e\n$s');
      if (!mounted) return;
      setState(() => _mobileVerified = false);
      _showErrorDialog('Error', 'Failed to check mobile: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _checkingMobile = false);
    }
  }

  Future<void> _submitSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_mobileVerified) {
      _showErrorDialog(
        'Mobile Not Verified',
        'Please verify your mobile number first',
      );
      return;
    }

    if (_password.text != _confirmPassword.text) {
      _showErrorDialog('Password Mismatch', 'Passwords do not match');
      return;
    }

    setState(() => _loading = true);

    try {
      print('📝 Submitting signup form...');

      final result = await AuthService.register(
        shopName: _shopName.text.trim(),
        ownerName: _ownerName.text.trim(),
        mobile: _mobile.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        businessType: _businessType ?? 'Others',
        address: _address.text.trim(),
        taxId: _taxId.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        print('✅ Signup successful');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome ${_shopName.text}! Your shop has been created.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ShopHomePage()),
            );
          }
        });
      } else {
        _showErrorDialog(
          'Signup Failed',
          result['error'] ?? result['message'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        _showErrorDialog('Connection Error', 'Failed to create account:\n$e');
      }
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
      backgroundColor: const Color.fromARGB(255, 176, 179, 175),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
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
                              'Register Your Shop\nStart selling today',
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
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Shop Name
                          TextFormField(
                            controller: _shopName,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Shop name',
                              prefixIcon: Icon(Icons.store),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter shop name'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Owner Name
                          TextFormField(
                            controller: _ownerName,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Owner name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter owner name'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Mobile Number with Verification
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _mobile,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  maxLength: 15,
                                  decoration: InputDecoration(
                                    labelText: 'Mobile number',
                                    prefixIcon: const Icon(Icons.phone_android),
                                    counterText: '',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _mobileVerified
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Enter mobile';
                                    if (v.trim().length < 7)
                                      return 'Invalid number';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D47A1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _checkingMobile
                                      ? null
                                      : _checkMobileAvailability,
                                  child: _checkingMobile
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Verify',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Email
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Business email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Enter email';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                                return 'Enter valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Business Type
                          DropdownButtonFormField<String>(
                            initialValue: _businessType,
                            items: _types
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _businessType = v),
                            decoration: const InputDecoration(
                              labelText: 'Business type',
                              prefixIcon: Icon(Icons.category_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Select type' : null,
                          ),
                          const SizedBox(height: 12),

                          // Address
                          TextFormField(
                            controller: _address,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Shop address',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter address'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Tax ID (optional)
                          TextFormField(
                            controller: _taxId,
                            decoration: const InputDecoration(
                              labelText: 'Tax / GST ID (optional)',
                              prefixIcon: Icon(Icons.receipt_long),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _password,
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
                              if (v == null || v.isEmpty)
                                return 'Enter password';
                              if (v.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPassword,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Confirm password';
                              if (v != _password.text)
                                return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Signup Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _loading ? null : _submitSignUp,
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Create my Shop',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account?',
                                style: TextStyle(color: Colors.black87),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Footer text
                          Text(
                            'Sign up to start listing products, run promotions and track orders — watch your sales grow.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
