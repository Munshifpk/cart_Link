/// Stub for non-web platforms (Android, iOS, etc.)

/// Check if browser notifications are supported (always false on non-web)
bool isNotificationSupported() {
  return false;
}

/// Get current notification permission status (empty on non-web)
String getNotificationPermission() {
  return 'default';
}

/// Request notification permission (no-op on non-web)
Future<String> requestNotificationPermission() async {
  return 'default';
}

/// Show a browser notification (no-op on non-web)
void showNotification(String title, String body, {String? icon}) {
  // No-op on non-web platforms
}
