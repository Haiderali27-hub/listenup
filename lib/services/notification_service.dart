// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  // final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const String _baseUrl = 'http://13.61.5.249:8000';

  Future<void> initialize() async {
    print('🔑 NotificationService initializing...');

    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );
    print('✅ Notification permission requested and local notifications initialized.');
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