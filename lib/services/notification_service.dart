import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _baseUrl = 'http://16.171.115.187:8000';

  Future<void> initialize() async {
    // Request permission for notifications
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

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
      },
    );

    // Get initial token and register it
    String? token = await _fcm.getToken();
    if (token != null) {
      await _updateFcmToken(token);
      await _saveFcmTokenToFirestore(token);
    }

    // Handle FCM token refresh
    _fcm.onTokenRefresh.listen((token) async {
      // Update token in your backend
      _updateFcmToken(token);
    });

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap
    });
  }

  Future<void> _updateFcmToken(String token) async {
    try {
      // Get the current user's ID token
      String? idToken = await _auth.currentUser?.getIdToken();
      if (idToken == null) {
        print('No user logged in, cannot register device token');
        return;
      }

      // Register the device token with the backend
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/auth/register-device-token/')) //url for fcm and id tokem
        ..fields['token'] = idToken
        ..fields['device_token'] = token;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        print('Device token registered successfully');
      } else {
        print('Failed to register device token: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error registering device token: $e');
    }
  }

  Future<void> _saveFcmTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No user logged in, cannot save FCM token to Firestore');
      return;
    }
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(), // Optional: track last update time
      }, SetOptions(merge: true)); // Use merge: true to update without overwriting other fields
      print('✅ Successfully saved FCM token to Firestore for user ${user.uid}');
    } catch (e) {
      print('❌ Error saving FCM token to Firestore: $e');
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
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
      message.notification?.title ?? 'Sound Detected',
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
      // Add a sound if you have one configured for the channel
      // sound: RawResourceAndroidNotificationSound('your_sound_file'),
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use a unique ID for each notification to prevent overwriting
    final int notificationId = DateTime.now().millisecondsSinceEpoch % 2000000000; // Generate a unique ID

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: 'local_detection', // Optional payload
    );
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
} 