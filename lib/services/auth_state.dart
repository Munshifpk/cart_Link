class AuthState {
  /// Simple in-memory holder for the currently authenticated owner/customer.
  /// This is a minimal approach for the local dev/demo; replace with
  /// proper secure storage (SharedPreferences, secure storage, provider, etc.)
  static Map<String, dynamic>? currentOwner;

  static void setOwner(Map<String, dynamic>? owner) {
    currentOwner = owner;
  }

  /// Currently authenticated customer (if any). Use `setCustomer` to update.
  static Map<String, dynamic>? currentCustomer;

  static void setCustomer(Map<String, dynamic>? customer) {
    currentCustomer = customer;
  }
}