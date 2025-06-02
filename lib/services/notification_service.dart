import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          print('Notification tapped: ${response.payload}');
        },
      );

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        throw Exception('Notification permission not granted');
      }

      // Get FCM token
      final token = await _messaging.getToken();
      if (token == null) {
        throw Exception('Failed to get FCM token');
      }

      // Register token with backend
      await _apiService.registerDeviceToken(token);

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        print('FCM token refreshed: ${newToken.substring(0, 10)}...');
        await _apiService.registerDeviceToken(newToken);
      });

      // Handle incoming messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          _showNotification(message);
        }
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Message opened app from background state!');
        print('Message data: ${message.data}');
      });

      _isInitialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
      throw Exception('Failed to initialize NotificationService: $e');
    }
  }

  Future<void> _updateFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        throw Exception('Failed to get FCM token');
      }

      await _apiService.registerDeviceToken(token);
      print('FCM token updated successfully');
    } catch (e) {
      print('Error updating FCM token: $e');
      throw Exception('Failed to update FCM token: $e');
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'sound_detection_channel',
      'Sound Detection',
      channelDescription: 'Notifications for detected sounds',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Sound Detected',
      message.notification?.body ?? 'A sound was detected',
      details,
      payload: json.encode(message.data),
    );
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
} 