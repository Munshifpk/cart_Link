import 'dart:html' as html show Notification;

/// Check if browser notifications are supported
bool isNotificationSupported() {
  return html.Notification.supported;
}

/// Get current notification permission status
String? getNotificationPermission() {
  return html.Notification.permission;
}

/// Request notification permission from browser
Future<String> requestNotificationPermission() async {
  return await html.Notification.requestPermission();
}

/// Show a browser notification
void showNotification(String title, String body, {String? icon}) {
  html.Notification(title, body: body, icon: icon ?? '/favicon.png');
}
