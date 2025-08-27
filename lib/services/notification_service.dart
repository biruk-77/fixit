// lib/services/notification_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationService {
  // Singleton pattern to ensure only one instance of the service
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stream to handle notification taps from anywhere in the app
  final StreamController<String?> onNotificationTapped =
      StreamController.broadcast();

  Future<void> init() async {
    // The small icon that appears in the status bar.
    // Make sure 'app_notification_icon.png' exists in 'android/app/src/main/res/drawable'
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_notification_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // This function is called when a notification is tapped
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          print('NOTIFICATION TAPPED with payload: ${response.payload}');
          onNotificationTapped.add(response.payload);
        }
      },
    );
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // This channel is crucial for Android 8.0+
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            description:
                'This channel is used for important app notifications.',
            importance: Importance.max,
          ),
        );
    // Request notification permissions for different OS versions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Shows a rich notification with a large image.
  /// This is the core function that handles network images and local placeholders.
  // NEW AND CORRECT METHOD

  /// Shows a rich notification.
  /// For chat messages, provide an `imageUrl` to show the sender's avatar as a small icon.
  /// For other notifications, the `imageUrl` can be used for a large picture style.
  Future<void> showRichNotification({
    required String title,
    required String body,
    String? imageUrl,
    required String payload,
    bool isChatMessage = false, // ADD THIS NEW PARAMETER
  }) async {
    // This helper function will download the image OR get the local placeholder path
    final String? imagePath = await _prepareImageForNotification(imageUrl);
    final AndroidBitmap<Object>? largeIcon = imagePath != null
        ? FilePathAndroidBitmap(imagePath)
        : null;

    // --- THIS IS THE KEY LOGIC CHANGE ---

    // For chat messages, we want a simple style with a large icon.
    // For other notifications, we can show a big picture.
    final StyleInformation? styleInformation = isChatMessage
        ? BigTextStyleInformation(body) // Shows more text when expanded
        : largeIcon != null
        ? BigPictureStyleInformation(
            largeIcon, // The big picture itself
            largeIcon: largeIcon, // The small icon when collapsed
            contentTitle: title,
            summaryText: body,
          )
        : null;

    final AndroidNotificationDetails
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel', // Channel ID must match the one created above
      'High Importance Notifications',
      channelDescription: 'Channel for important app notifications.',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: styleInformation,
      largeIcon:
          largeIcon, // <-- THIS IS THE PROPERTY FOR THE SMALL CIRCLE ICON
      icon: 'app_notification_icon',
    );

    // For iOS, we can add the image as an attachment.
    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentSound: true,
          attachments: imagePath != null
              ? <DarwinNotificationAttachment>[
                  DarwinNotificationAttachment(imagePath),
                ]
              : null,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<String?> _prepareImageForNotification(String? url) async {
    // If the URL is valid and starts with http, try to download it.
    if (url != null && url.trim().startsWith('http')) {
      return await _downloadAndSaveFile(url, 'notification_image.jpg');
    }
    // If the URL is null, empty, or invalid, use the local app icon as a placeholder.
    print("Image URL is invalid. Using local placeholder icon.");
    return await _getPlaceholderIconPath();
  }

  /// Downloads an image from a URL and saves it to a temporary directory.
  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/$fileName';
      final http.Response response = await http.get(Uri.parse(url));

      // Check if the download was successful
      if (response.statusCode == 200) {
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        print("Failed to download image: Status code ${response.statusCode}");
        return await _getPlaceholderIconPath(); // Fallback on download error
      }
    } catch (e) {
      print('Error downloading notification image: $e');
      return await _getPlaceholderIconPath(); // Fallback on any exception
    }
  }

  /// Copies your local asset icon to a temporary directory so the plugin can use it.
  Future<String> _getPlaceholderIconPath() async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/placeholder_icon.png';
      final ByteData data = await rootBundle.load('assets/icon/icon.png');
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(filePath).writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      print("Error creating placeholder icon file: $e");
      // If even this fails, return an empty string to prevent a crash.
      return '';
    }
  }
}
