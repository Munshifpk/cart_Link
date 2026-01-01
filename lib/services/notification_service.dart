import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cart_link/services/auth_state.dart';
import 'package:cart_link/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Conditional import - dart:html only available on web
import 'notification_web.dart' if (dart.library.io) 'notification_stub.dart' as web;

class NotificationMessage {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  NotificationMessage({
    this.title,
    this.body,
    required this.data,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Timer? _pollingTimer;
  String? _lastNotificationId;
  final StreamController<NotificationMessage> _messageStreamController =
      StreamController<NotificationMessage>.broadcast();

  Stream<NotificationMessage> get onMessageStream => _messageStreamController.stream;

  /// Initialize notification service (works without Firebase)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission
      await requestPermission();

      // Start polling for new notifications from backend
      _startPolling();

      _initialized = true;
      print('[NotificationService] Initialized successfully (Local only)');
    } catch (e) {
      print('[NotificationService] Initialization error: $e');
    }
  }

  /// Start polling backend for new notifications
  void _startPolling() {
    // Poll every 30 seconds for new notifications
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForNewNotifications();
    });
    // Check immediately on start
    _checkForNewNotifications();
  }

  /// Check backend for new notifications
  Future<void> _checkForNewNotifications() async {
    try {
      // Don't check if no one is listening
      if (!_messageStreamController.hasListener) {
        return;
      }

      final customerId = AuthState.currentCustomer?['_id'] ?? 
                        AuthState.currentCustomer?['id'];
      if (customerId == null) return;

      final uri = backendUri('$kApiNotifications/$customerId');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifications = (data is Map && data['data'] is List)
            ? data['data'] as List
            : (data is List ? data : <dynamic>[]);
        
        // Check for unread notifications
        final unreadNotifications = notifications
            .whereType<Map<String, dynamic>>()
            .where((n) => !(n['isRead'] ?? false))
            .toList();
        
        if (unreadNotifications.isNotEmpty) {
          final latestNotification = unreadNotifications.first;
          final notificationId = latestNotification['_id']?.toString() ?? 
                                latestNotification['id']?.toString();
          
          // Only show if it's a new notification we haven't seen
          if (notificationId != null && notificationId != _lastNotificationId) {
            _lastNotificationId = notificationId;
            
            final title = latestNotification['title']?.toString() ?? 'New Notification';
            final body = latestNotification['message']?.toString() ?? '';
            
            // Show local notification
            await _showLocalNotification(
              title: title,
              body: body,
              payload: jsonEncode(latestNotification),
            );
            
            // Emit to stream only if there are listeners
            if (_messageStreamController.hasListener) {
              _messageStreamController.add(NotificationMessage(
                title: title,
                body: body,
                data: latestNotification,
              ));
            }
          }
        }
      }
    } catch (e) {
      print('[NotificationService] Polling error: $e');
    }
  }

  /// Manually trigger notification check
  Future<void> checkNow() async {
    await _checkForNewNotifications();
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) {
      // Web doesn't need initialization for notifications
      print('[NotificationService] Web platform - skipping local notification init');
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (!kIsWeb && Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'cart_link_channel',
        'Cart Link Notifications',
        description: 'Notifications for offers, updates, and order status',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('[LocalNotification] Tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (kIsWeb) {
        // Use browser notification API for web
        _showWebNotification(title, body);
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'cart_link_channel',
        'Cart Link Notifications',
        channelDescription: 'Notifications for offers, updates, and order status',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('[LocalNotification] Shown: $title');
    } catch (e) {
      print('[LocalNotification] Show error: $e');
    }
  }

  /// Show web notification using browser API
  void _showWebNotification(String title, String body) {
    try {
      if (web.isNotificationSupported()) {
        web.showNotification(title, body, icon: '/favicon.png');
        print('[WebNotification] Shown: $title');
      } else {
        print('[WebNotification] Not supported in this browser');
      }
    } catch (e) {
      print('[WebNotification] Show error: $e');
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      if (kIsWeb) {
        // Request permission for web notifications
        return await _requestWebNotificationPermission();
      }
      
      if (Platform.isAndroid) {
        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        final granted = await androidImplementation?.requestNotificationsPermission();
        print('[LocalNotification] Permission granted: $granted');
        return granted ?? false;
      } else if (Platform.isIOS) {
        final iosImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        
        final granted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('[LocalNotification] Permission granted: $granted');
        return granted ?? false;
      }
      return true;
    } catch (e) {
      print('[LocalNotification] Permission request error: $e');
      return false;
    }
  }

  /// Request web notification permission
  Future<bool> _requestWebNotificationPermission() async {
    try {
      if (!web.isNotificationSupported()) {
        print('[WebNotification] Not supported');
        return false;
      }

      final permission = web.getNotificationPermission();
      
      if (permission == 'granted') {
        print('[WebNotification] Permission already granted');
        return true;
      }
      
      if (permission == 'denied') {
        print('[WebNotification] Permission denied');
        return false;
      }

      // Request permission
      final result = await web.requestNotificationPermission();
      final granted = result == 'granted';
      print('[WebNotification] Permission result: $result');
      return granted;
    } catch (e) {
      print('[WebNotification] Permission request error: $e');
      return false;
    }
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Dispose
  void dispose() {
    _pollingTimer?.cancel();
    _messageStreamController.close();
  }
}
