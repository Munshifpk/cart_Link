import 'auth_storage.dart';

class AuthState {
  /// In-memory cache of the currently authenticated owner/customer.
  /// This is synced with persistent storage (SharedPreferences).
  static Map<String, dynamic>? currentOwner;
  static Map<String, dynamic>? currentCustomer;

  /// Set shop owner and persist to storage
  static Future<void> setOwner(Map<String, dynamic>? owner, {String? token}) async {
    currentOwner = owner;
    
    if (owner != null && token != null) {
      await AuthStorage.saveShopSession(token: token, shopData: owner);
    } else if (owner == null) {
      await AuthStorage.clearShopSession();
    }
  }

  /// Set customer and persist to storage
  static Future<void> setCustomer(Map<String, dynamic>? customer, {String? token}) async {
    currentCustomer = customer;
    
    if (customer != null && token != null) {
      await AuthStorage.saveCustomerSession(token: token, customerData: customer);
    } else if (customer == null) {
      await AuthStorage.clearCustomerSession();
    }
  }

  /// Load shop owner from persistent storage
  static Future<void> loadOwnerFromStorage() async {
    final shopData = await AuthStorage.getShopData();
    if (shopData != null) {
      currentOwner = shopData;
    }
  }

  /// Load customer from persistent storage
  static Future<void> loadCustomerFromStorage() async {
    final customerData = await AuthStorage.getCustomerData();
    if (customerData != null) {
      currentCustomer = customerData;
    }
  }

  /// Check if shop owner is logged in
  static Future<bool> isOwnerLoggedIn() async {
    return await AuthStorage.isShopLoggedIn();
  }

  /// Check if customer is logged in
  static Future<bool> isCustomerLoggedIn() async {
    return await AuthStorage.isCustomerLoggedIn();
  }

  /// Logout shop owner
  static Future<void> logoutOwner() async {
    currentOwner = null;
    await AuthStorage.clearShopSession();
  }

  /// Logout customer
  static Future<void> logoutCustomer() async {
    currentCustomer = null;
    await AuthStorage.clearCustomerSession();
  }

  /// Clear all authentication data
  static Future<void> clearAll() async {
    currentOwner = null;
    currentCustomer = null;
    await AuthStorage.clearAllSessions();
  }
}