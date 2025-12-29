import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persistent authentication storage using SharedPreferences.
/// Stores user sessions that persist until explicit logout.
class AuthStorage {
  static const String _keyCustomerToken = 'customer_token';
  static const String _keyCustomerData = 'customer_data';
  static const String _keyShopToken = 'shop_token';
  static const String _keyShopData = 'shop_data';

  // Customer Session Management
  
  /// Save customer authentication session
  static Future<void> saveCustomerSession({
    required String token,
    required Map<String, dynamic> customerData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomerToken, token);
    await prefs.setString(_keyCustomerData, jsonEncode(customerData));
  }

  /// Get customer token
  static Future<String?> getCustomerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomerToken);
  }

  /// Get customer data
  static Future<Map<String, dynamic>?> getCustomerData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCustomerData);
    if (jsonStr == null) return null;
    
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding customer data: $e');
      return null;
    }
  }

  /// Check if customer is logged in
  static Future<bool> isCustomerLoggedIn() async {
    final token = await getCustomerToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear customer session (logout)
  static Future<void> clearCustomerSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomerToken);
    await prefs.remove(_keyCustomerData);
  }

  // Shop Owner Session Management
  
  /// Save shop owner authentication session
  static Future<void> saveShopSession({
    required String token,
    required Map<String, dynamic> shopData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyShopToken, token);
    await prefs.setString(_keyShopData, jsonEncode(shopData));
  }

  /// Get shop token
  static Future<String?> getShopToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyShopToken);
  }

  /// Get shop data
  static Future<Map<String, dynamic>?> getShopData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyShopData);
    if (jsonStr == null) return null;
    
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding shop data: $e');
      return null;
    }
  }

  /// Check if shop owner is logged in
  static Future<bool> isShopLoggedIn() async {
    final token = await getShopToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear shop session (logout)
  static Future<void> clearShopSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyShopToken);
    await prefs.remove(_keyShopData);
  }

  // General Methods
  
  /// Clear all sessions (both customer and shop)
  static Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomerToken);
    await prefs.remove(_keyCustomerData);
    await prefs.remove(_keyShopToken);
    await prefs.remove(_keyShopData);
  }

  /// Get the current user type ('customer', 'shop', or null)
  static Future<String?> getCurrentUserType() async {
    final hasCustomer = await isCustomerLoggedIn();
    final hasShop = await isShopLoggedIn();
    
    if (hasCustomer) return 'customer';
    if (hasShop) return 'shop';
    return null;
  }
}
