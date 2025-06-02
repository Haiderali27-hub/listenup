import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class SoundService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final ApiService _apiService = ApiService();
  bool _isInitialized = false;
  bool _isRecording = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }

      // Initialize recorder
      await _recorder.openRecorder();
      _isInitialized = true;
      print('SoundService initialized successfully');
    } catch (e) {
      print('Error initializing SoundService: $e');
      throw Exception('Failed to initialize SoundService: $e');
    }
  }

  Future<void> startRecording() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isRecording) {
      print('Already recording');
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 16000,
      );
      _isRecording = true;
      print('Started recording to: $filePath');
    } catch (e) {
      print('Error starting recording: $e');
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) {
      print('Not recording');
      return null;
    }

    try {
      final filePath = await _recorder.stopRecorder();
      _isRecording = false;
      print('Stopped recording at: $filePath');

      if (filePath == null) {
        throw Exception('Failed to get recording file path');
      }

      // Verify file exists and has content
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Recording file does not exist');
      }

      final fileSize = await file.length();
      if (fileSize <= 44) { // WAV header is 44 bytes
        throw Exception('Recording file is too small or empty');
      }

      print('Recording file size: $fileSize bytes');
      return filePath;
    } catch (e) {
      print('Error stopping recording: $e');
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<Map<String, dynamic>> detectSound() async {
    try {
      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        throw Exception('Failed to get FCM token');
      }

      // Get recording file path
      final filePath = await stopRecording();
      if (filePath == null) {
        throw Exception('No recording available');
      }

      // Send to API
      final result = await _apiService.detectSound(
        audioPath: filePath,
        fcmToken: fcmToken,
      );

      // Clean up the temporary file
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Warning: Failed to delete temporary file: $e');
      }

      return result;
    } catch (e) {
      print('Error in detectSound: $e');
      throw Exception('Failed to detect sound: $e');
    }
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    if (_isInitialized) {
      await _recorder.closeRecorder();
      _isInitialized = false;
    }
  }
} 