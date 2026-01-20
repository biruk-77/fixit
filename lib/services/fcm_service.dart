import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
class FCMService {
  static final FCMService _instance = FCMService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Request notification permissions (iOS)
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ User granted provisional notification permission');
      } else {
        debugPrint('❌ User denied notification permission');
      }

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $token');

      // Handle foreground messages (when app is open)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is closed)
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle message when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      debugPrint('✅ FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  /// Handle messages received while app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground message received:');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Show notification while app is open
    await _notificationService.showRichNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new update',
      imageUrl: message.data['imageUrl'],
      payload: message.data['chatRoomId'] ?? message.data['jobId'] ?? 'default',
      isChatMessage: message.data['type'] == 'message_received',
    );
  }

  /// Handle messages received while app is in background
  /// This must be a top-level function
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📬 Background message received:');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Initialize notification service for background
    final notificationService = NotificationService();
    await notificationService.showRichNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new update',
      imageUrl: message.data['imageUrl'],
      payload: message.data['chatRoomId'] ?? message.data['jobId'] ?? 'default',
      isChatMessage: message.data['type'] == 'message_received',
    );
  }

  /// Handle when user taps on notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('🔔 Notification tapped:');
    debugPrint('Data: ${message.data}');

    // Navigate based on notification type
    final chatRoomId = message.data['chatRoomId'];
    final jobId = message.data['jobId'];

    if (chatRoomId != null) {
      debugPrint('Navigating to chat: $chatRoomId');
      // Navigation will be handled by your app's router
    } else if (jobId != null) {
      debugPrint('Navigating to job: $jobId');
      // Navigation will be handled by your app's router
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }
}
