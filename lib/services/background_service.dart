import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_app/services/sound_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sound_app/services/notification_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final SoundService _soundService = SoundService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  static const String _baseUrl = 'http://16.171.115.187:8000';
  Timer? _detectionTimer;
  bool _isInitialized = false;
  bool _isListening = false;
  String? _lastRecordedFilePath;
  bool _isStopping = false;
  String? _currentRecordingPath;
  String? _lastProcessedFilePath;
  DateTime? _lastDetectionTime;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;
  static const Duration _minTimeBetweenDetections = Duration(seconds: 5);
  static const Duration _recordingDuration = Duration(seconds: 5);
  static const Duration _maxRecordingDuration = Duration(seconds: 30);
  static const Duration _detectionInterval = Duration(seconds: 10);
  static const Duration _retryDelay = Duration(seconds: 5);
  static const int _maxRetries = 3;
  static const Duration _requestTimeout = Duration(seconds: 30);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted or denied');
      }
      
      _isInitialized = true;
      print('🎤 Audio recorder initialized successfully (using record package)');
    } catch (e) {
      print('❌ Error initializing background service: $e');
      rethrow;
    }
  }

  Future<void> startListening() async {
    print('🎤 Starting to listen...');
    
    // If already listening or stopping, wait for stop to complete
    if (_isListening || _isStopping) {
      print('⚠️ Already listening or stopping, waiting for stop to complete...');
      await stopListening();
      // Add a small delay to ensure everything is cleaned up
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      print('🎤 Starting audio recorder (using record package)...');
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/audio_$timestamp.wav';
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: path,
      );
      
      _isListening = true;
      _currentRecordingPath = path;
      print('✅ Recording started successfully at: $path');

      // Start the detection timer
      _startDetectionTimer();
    } catch (e) {
      print('❌ Error starting recording: $e');
      _isListening = false;
      _currentRecordingPath = null;
      rethrow;
    }
  }

  Future<void> stopListening() async {
    print('🛑 Attempting to stop listening...');
    
    if (_isStopping) {
      print('⚠️ Already in the process of stopping, returning...');
      return;
    }
    
    _isStopping = true;

    try {
      // First cancel the timer
      if (_detectionTimer != null) {
        print('⏱️ Cancelling detection timer...');
        _detectionTimer!.cancel();
        _detectionTimer = null;
      }

      // Then stop the recorder if it's active
      if (_isListening) {
        print('⏹️ Stopping audio recorder...');
        try {
          await _audioRecorder.stop();
          print('✅ Recording stopped successfully');
        } catch (e) {
          print('❌ Error stopping recorder: $e');
        } finally {
          _isListening = false;
          _currentRecordingPath = null;
        }
      }

      print('✅ Stop listening completed successfully');
    } catch (e) {
      print('❌ Error in stopListening: $e');
      rethrow;
    } finally {
      _isStopping = false;
    }
  }

  void _startDetectionTimer() {
    print('⏱️ Starting detection timer...');
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(_detectionInterval, (timer) async {
      if (!_isListening || _isStopping) {
        print('⚠️ Timer tick but not listening or stopping, cancelling timer...');
        timer.cancel();
        return;
      }

      try {
        await _processCurrentRecording();
      } catch (e) {
        print('❌ Error in detection timer: $e');
        _consecutiveFailures++;
        
        if (_consecutiveFailures >= _maxConsecutiveFailures) {
          print('❌ Too many consecutive failures, stopping detection...');
          await stopListening();
        }
      }
    });
    print('✅ Detection timer started');
  }

  Future<void> _processCurrentRecording() async {
    if (!_isListening || _isStopping || _currentRecordingPath == null) {
      print('⚠️ Cannot process recording: isListening=$_isListening, isStopping=$_isStopping, path=${_currentRecordingPath != null}');
      return;
    }

    print('🔄 Processing current recording...');
    final file = File(_currentRecordingPath!);
    
    if (!await file.exists()) {
      print('❌ Recording file does not exist: ${_currentRecordingPath}');
      return;
    }

    final fileSize = await file.length();
    print('📊 Current recording size: $fileSize bytes');

    if (fileSize < 1000) {
      print('⚠️ File too small, skipping detection');
      return;
    }

    try {
      await _detectAndSaveSound(file);
      _consecutiveFailures = 0;
    } catch (e) {
      print('❌ Error detecting sound: $e');
      rethrow;
    }
  }

  Future<void> _detectAndSaveSound(File file) async {
    if (!_isListening || _isStopping || _currentRecordingPath == null) {
      print('⚠️ Cannot detect sound: isListening=$_isListening, isStopping=$_isStopping, path=${_currentRecordingPath != null}');
      return;
    }

    print('📁 Got audio file at: $_currentRecordingPath');
    
    if (await file.exists()) {
      final fileSize = await file.length();
      print('📊 Audio file size: ${fileSize} bytes');
      if (fileSize <= 44) {
        print('⚠️ Warning: Audio file is suspiciously small or empty!');
        print('   Expected size > 44 bytes for 5 seconds of audio');
        print('   Current size: $fileSize bytes');
        print('   File path: $_currentRecordingPath');
        
        try {
          final bytes = await file.readAsBytes();
          print('📝 First 100 bytes of file: ${bytes.take(100).toList()}');
        } catch (e) {
          print('❌ Error reading file content: $e');
        }
        // Skip this detection cycle if file is too small
        await _restartRecording();
        return;
      }
    } else {
      print('❌ Error: Audio file does not exist!');
      await _restartRecording();
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ No user logged in, skipping detection');
      await _restartRecording();
      return;
    }

    print('📡 Calling sound detection service...');
    try {
      final result = await _soundService.detectSound(_currentRecordingPath!);
      print('📥 API result received: $result');

      final pushResponse = result['push_response'];
      if (pushResponse != null && pushResponse.isNotEmpty) {
        print('🔄 Processing push_response: $pushResponse');
        final parts = pushResponse.split(',');
        if (parts.length >= 3) {
          final confidence = double.tryParse(parts[0]);
          final label = parts[2];
          print('📊 Parsed confidence: $confidence, label: $label');

          if (confidence != null && confidence > 0.7) {
            print('✅ High confidence detection! Saving to Firestore...');
            await _handleSoundDetection({'label': label, 'confidence': confidence});
          } else {
            print('⚠️ Confidence too low ($confidence), not saving.');
          }
        } else {
          print('⚠️ Unexpected push_response format or insufficient parts: $pushResponse');
        }
      } else {
        print('⚠️ push_response is null or empty');
      }
    } catch (e) {
      print('❌ Error in sound detection: $e');
      // Continue with next recording cycle
    }
    
    await _restartRecording();
  }

  Future<void> _restartRecording() async {
    if (!_isListening || _isStopping) {
      print('⚠️ Cannot restart recording: isListening=$_isListening, isStopping=$_isStopping');
      return;
    }
    
    try {
      final newFilePath = '${_currentRecordingPath!.split('_').first}_${DateTime.now().millisecondsSinceEpoch}.wav';
      print('🎤 Restarting audio recorder (using record package)...');
      print('📁 New recording path: $newFilePath');
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: newFilePath,
      );
      print('✅ Audio recorder restarted successfully');
      print('🔄 Ready for next detection cycle');
    } catch (e) {
      print('❌ Error restarting recording: $e');
      print('Stack trace: ${StackTrace.current}');
      // Try to recover by reinitializing
      try {
        print('🔄 Attempting to recover by reinitializing...');
        _isInitialized = false;
        await initialize();
        if (!_isStopping) {
          await _restartRecording();
        }
      } catch (recoveryError) {
        print('❌ Recovery failed: $recoveryError');
        // If recovery fails, we should stop listening to prevent further errors
        await stopListening();
      }
    }
  }

  Future<void> _handleSoundDetection(Map<String, dynamic> result) async {
    print('\n📝 --- Handling Sound Detection ---');
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('⚠️ No user ID found, cannot save detection');
      return;
    }

    print('💾 Writing to Firestore: $result');
    try {
      await _firestore.collection('sound_detections').add({
        'userId': userId,
        'label': result['label'],
        'confidence': result['confidence'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Successfully saved to Firestore');

      // Trigger local notification after successful save
      await _notificationService.showLocalNotification(
        title: 'Sound Detected!',
        body: 'Detected sound: ${result['label']}',
      );

    } catch (e) {
      print('❌ Error in _handleSoundDetection: $e');
    }
    print('📝 --- Sound Detection Handling Complete ---\n');
  }

  Future<void> dispose() async {
    await stopListening();
    if (_isInitialized) {
      _audioRecorder.dispose();
      _isInitialized = false;
      print('🔌 Audio recorder disposed (using record package)');
    }
  }

  bool get isListening => _isListening;
  
  String? get lastRecordedFilePath => _lastRecordedFilePath;
} 