import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_app/services/sound_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final SoundService _soundService = SoundService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _detectionTimer;
  bool _isInitialized = false;
  bool _isListening = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission not granted');
      }

      await _audioRecorder.openRecorder();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing background service: $e');
      rethrow;
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isListening) return;

    try {
      await _audioRecorder.startRecorder(
        toFile: 'audio.aac',
        codec: Codec.aacADTS,
      );
      _isListening = true;

      // Start periodic sound detection
      _detectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!_isListening) return;

        try {
          final path = await _audioRecorder.stopRecorder();
          if (path != null) {
            final result = await _soundService.detectSound(path);
            if (result['confidence'] > 0.7) { // Only process high confidence detections
              await _handleSoundDetection(result);
            }
          }
          // Restart recording immediately
          await _audioRecorder.startRecorder(
            toFile: 'audio.aac',
            codec: Codec.aacADTS,
          );
        } catch (e) {
          print('Error in sound detection: $e');
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
      rethrow;
    }
  }

  Future<void> stopListening() async {
    _detectionTimer?.cancel();
    if (_isListening) {
      await _audioRecorder.stopRecorder();
      _isListening = false;
    }
  }

  Future<void> _handleSoundDetection(Map<String, dynamic> result) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Store in Firestore
    await _firestore.collection('sound_detections').add({
      'userId': userId,
      'label': result['label'],
      'confidence': result['confidence'],
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Send notification
    await FirebaseMessaging.instance.sendMessage(
      to: userId,
      data: {
        'title': 'Sound Detected',
        'body': 'Detected ${result['label']} with ${(result['confidence'] * 100).toStringAsFixed(1)}% confidence',
        'sound': result['label'],
      },
    );
  }

  Future<void> dispose() async {
    await stopListening();
    if (_isInitialized) {
      await _audioRecorder.closeRecorder();
      _isInitialized = false;
    }
  }
} 