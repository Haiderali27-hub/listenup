import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _baseUrl = 'http://16.171.115.187:8000';

  Future<void> initialize() async {
    print('🔑 NotificationService initializing...');

    // Request notification permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('📱 Notification permission status: ${settings.authorizationStatus}');

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

    // Handle messages received while the app is in the foreground
    // We will not show notifications automatically for data messages here.
    // The local notification is triggered by the background service after API response.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received: ${message.messageId}');
      // Optionally process the message data if needed when app is in foreground
      // For example, if you wanted to update UI in real-time.
      // print('Foreground message data: ${message.data}');
    });

    // Background messages are handled by a top-level function.
    // Ensure firebaseMessagingBackgroundHandler is defined outside of any class.

    // Get FCM token and update it
    await _updateFCMToken();

    // Handle FCM token refresh
    _messaging.onTokenRefresh.listen((token) async {
      // Update token in your backend
      await _updateFCMToken();
    });
  }

  Future<void> _updateFCMToken() async {
    try {
      print('🔄 Attempting to update FCM token with backend...');
      
      // Get the current user's ID token
      print('🔍 Getting current user ID token...');
      final idToken = await _auth.currentUser?.getIdToken();
      print('✅ Got ID token: ${idToken != null ? 'Present' : 'Missing'}');

      if (idToken == null) {
        print('❌ No ID token available, cannot update FCM token');
        return;
      }

      // Get the FCM token
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        print('❌ No FCM token available');
        return;
      }

      print('✅ Got FCM token: ${fcmToken.substring(0, 10)}...');

      // Save the FCM token to Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({'fcmToken': fcmToken}, SetOptions(merge: true));
        print('✅ FCM token saved to Firestore');
      }
    } catch (e) {
      print('❌ Error updating FCM token: $e');
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
    return await _messaging.getToken();
  }
} 