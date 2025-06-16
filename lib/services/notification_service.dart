// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    print('🔑 NotificationService initializing...');

    // Request notification permissions
    await _requestPermissions();
    print('✅ Notification permission requested and local notifications initialized.');

    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);
    print('✅ Local notifications initialized');

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('📱 Current FCM Token: $token');
    print('📱 Token Format: ${_analyzeTokenFormat(token)}');

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token Refreshed: $newToken');
      print('🔄 New Token Format: ${_analyzeTokenFormat(newToken)}');
    });

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Received foreground message:');
      print('  - Title: ${message.notification?.title}');
      print('  - Body: ${message.notification?.body}');
      print('  - Data: ${message.data}');

      // Re-introduce showing local notification for foreground messages,
      // using the content from message.notification payload.
      final notification = message.notification;
      if (notification != null) {
        String displayTitle = 'Sound Detected!';
        String displayBody = notification.body ?? 'A sound was detected.';

        // Attempt to parse the title if it contains the "jibberish" format (e.g., "ID,path,label")
        if (notification.title != null) {
          final parts = notification.title!.split(',');
          if (parts.length >= 3) {
            displayBody = parts[2]; // The sound label
            print('✨ Parsed notification body from title: $displayBody');
          } else {
            displayTitle = notification.title!;
            print('⚠️ Notification title not in expected format, using as is: ${notification.title}');
          }
        }

        _localNotifications.show(
          notification.hashCode, // Use hash code for unique ID, or other ID
          displayTitle,
          displayBody,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'sound_detection_channel',
              'Sound Detection',
              channelDescription: 'Notifications for detected sounds',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: message.data.toString(),
        );
        print('✅ Local notification shown for foreground FCM message.');
      } else {
        print('⚠️ Foreground FCM message without notification payload.');
      }

      // Keep processing push_response data for internal app logic if needed, but not for displaying notification.
      final pushResponse = message.data['push_response'];
      if (pushResponse != null && pushResponse is String) {
        final parts = pushResponse.split(',');
        if (parts.length >= 3) {
          final soundLabel = parts[2]; // e.g., "Crackle"
          print('✨ Parsed sound label from push_response (for data processing): $soundLabel');
        } else {
          print('⚠️ Unexpected push_response format: $pushResponse (for data processing).');
        }
      } else {
        print('⚠️ No valid push_response in message data (for data processing).');
      }
    });

    // Handle message when app is in background and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 App opened from background message:');
      print('  - Title: ${message.notification?.title}');
      print('  - Body: ${message.notification?.body}');
      print('  - Data: ${message.data}');
    });

    // Handle message when app is terminated and user taps notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('📨 App opened from terminated state:');
      print('  - Title: ${initialMessage.notification?.title}');
      print('  - Body: ${initialMessage.notification?.body}');
      print('  - Data: ${initialMessage.data}');
    }

    _isInitialized = true;
    print('✅ NotificationService initialized');
  }

  String _analyzeTokenFormat(String? token) {
    if (token == null) return 'No token available';
    
    final parts = token.split(':');
    if (parts.length != 2) return 'Invalid format: Should contain one colon';
    
    final prefix = parts[0];
    final suffix = parts[1];
    
    String analysis = 'Token Format Analysis:\n';
    analysis += '1. Length: ${token.length} characters\n';
    analysis += '2. Prefix: $prefix\n';
    analysis += '3. Suffix: $suffix\n';
    analysis += '4. Valid Format: ${prefix.startsWith('eG7DuctCTI') ? 'Yes' : 'No'}\n';
    
    return analysis;
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      await Permission.notification.request();
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'sound_detection_channel',
      'Sound Detection',
      channelDescription: 'Notifications for detected sounds',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Sound Detected!',
      message.notification?.body ?? 'A sound was detected',
      details,
      payload: message.data.toString(),
    );
  }

  /// Shows a local notification with a specific title and body.
  Future<void> showLocalNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'local_sound_detection_channel', // Unique channel ID for local notifications
      'Local Sound Detection',
      channelDescription: 'Notifications for locally detected sounds',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final int notificationId = DateTime.now().millisecondsSinceEpoch % 2000000000;

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: 'local_detection',
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'sound_detection_channel',
        'Sound Detection',
        channelDescription: 'Notifications for detected sounds',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
      );

      print('✅ Local notification shown: $title - $body');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  Future<String?> getToken() async {
    // No Firebase token logic remains
    return null;
  }
} 