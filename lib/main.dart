import 'package:cart_link/Admin/admin_home.dart';
import 'package:cart_link/Customer/customer_home.dart';
import 'package:cart_link/Shops/bottom bar/home-shops.dart';
import 'package:cart_link/services/auth_state.dart';
import 'package:cart_link/services/auth_storage.dart';
import 'package:cart_link/theme_data.dart';
import 'package:flutter/material.dart';
import 'Customer/login.dart';
import 'Customer/cart_page.dart';
import 'Shops/login-Shops.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    // optionally send to a logger / print
    print('FlutterError: ${details.exceptionAsString()}');
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cart Link',
      theme: AppTheme.light,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/cart': (context) => const CustomerCartPage(),
      },
    );
  }
}

/// Splash screen that checks for existing sessions and auto-logins
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Wait a moment for splash effect
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Check for existing sessions
      final userType = await AuthStorage.getCurrentUserType();

      if (!mounted) return;

      if (userType == 'customer') {
        // Load customer session
        await AuthState.loadCustomerFromStorage();
        final customerData = AuthState.currentCustomer;
        
        if (customerData != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CustomerHome(
                customer: Customer(
                  id: customerData['_id']?.toString(),
                  customerName: customerData['customerName'] ?? '',
                  email: customerData['email'],
                  mobile: customerData['mobile'] is int
                      ? customerData['mobile']
                      : (int.tryParse(customerData['mobile']?.toString() ?? '')),
                  address: customerData['address'],
                  createdAt: customerData['createdAt'] != null
                      ? DateTime.tryParse(customerData['createdAt'])
                      : null,
                ),
              ),
            ),
          );
          return;
        }
      } else if (userType == 'shop') {
        // Load shop session
        await AuthState.loadOwnerFromStorage();
        
        if (AuthState.currentOwner != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ShopHomePage()),
          );
          return;
        }
      }

      // No valid session found, go to home page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      print('Session check error: $e');
      // On error, go to home page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: ThemeColors.primaryGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart, size: 80, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Cart Link',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Limit tile width on larger screens
    final maxTileWidth = screenWidth > 800
        ? 300.0
        : (screenWidth - (screenWidth / 3)) / 2;
    final tileSize = maxTileWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Link'),
        backgroundColor: ThemeColors.primary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminHome()),
              );
            },
            child: const Text('Admin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      // Use a full-size Container so decorative background fills every screen size
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: ThemeColors.surface,
        child: Stack(
          children: [
            // Background graphics
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeColors.primary.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeColors.accent.withOpacity(0.08),
                ),
              ),
            ),
            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Motivational header
                    const Text(
                      'Choose Your Role',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start growing your business today',
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Tiles Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Shop Login Tile
                        Material(
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShopLoginPage(),
                              ),
                            ),
                            child: Container(
                              width: tileSize,
                              height: tileSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: ThemeColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: ThemeColors.primary.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background decorative elements
                                  Positioned(
                                    top: -30,
                                    right: -30,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -20,
                                    left: -20,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                    ),
                                  ),
                                  // Content centered both vertically and horizontally
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.store,
                                        size: 56,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Shop Owner',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Reach more\ncustomers',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Customer Login Tile
                        Material(
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            ),
                            child: Container(
                              width: tileSize,
                              height: tileSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: ThemeColors.accentGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: ThemeColors.accent.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background decorative elements
                                  Positioned(
                                    top: -30,
                                    right: -30,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -20,
                                    left: -20,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                    ),
                                  ),
                                  // Content centered both vertically and horizontally
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.shopping_bag,
                                        size: 56,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Customer',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Shop nearby\nstores',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    // Motivational text at bottom
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: ThemeColors.primary.withOpacity(0.06),
                        border: Border.all(
                          color: ThemeColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: ThemeColors.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Boost Your Sales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connect with thousands of customers and grow your business exponentially',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: ThemeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
