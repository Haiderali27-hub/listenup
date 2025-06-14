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
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final SoundService _soundService = SoundService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _baseUrl = 'http://13.61.5.249:8000';
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
  Timer? _recordingTimer;
  bool _isProcessing = false;
  Directory? _appDir;
  Function(String)? onShowMessage;
  Function(bool)? onProcessingStateChanged;
  final _lock = Lock();
  bool _isStarting = false;
  String? _processingPath;  // Separate path for processing

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔍 Checking microphone permissions...');
      
      // First check if permission is already granted
      var status = await Permission.microphone.status;
      print('📱 Current microphone permission status: $status');
      
      if (status.isDenied) {
        print('🔒 Requesting microphone permission...');
        status = await Permission.microphone.request();
        print('📱 New microphone permission status: $status');
      }
      
      if (!status.isGranted) {
        throw Exception('Microphone permission not granted. Current status: $status');
      }

      // Verify recorder permission
      print('🔍 Verifying audio recorder permission...');
      final hasPermission = await _audioRecorder.hasPermission();
      print('📱 Audio recorder permission status: $hasPermission');
      
      if (!hasPermission) {
        throw Exception('Audio recorder permission not granted');
      }

      // Test recorder initialization
      print('🔍 Testing recorder initialization...');
      try {
        final directory = await getApplicationDocumentsDirectory();
        final testPath = '${directory.path}/test_recording.wav';
        print('📁 Test recording path: $testPath');
        
        // Initialize recorder with proper configuration
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 128000,
          ),
          path: testPath,
        );
        
        // Wait a short time to ensure recording starts
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Stop recording
        await _audioRecorder.stop();
        
        // Verify the test file was created
        final testFile = File(testPath);
        if (await testFile.exists()) {
          final size = await testFile.length();
          print('📊 Test recording file size: $size bytes');
          await testFile.delete();
          print('✅ Test recording successful');
        } else {
          print('❌ Test recording file was not created');
          throw Exception('Test recording file was not created');
        }
      } catch (e) {
        print('❌ Failed to initialize audio recorder: $e');
        throw Exception('Failed to initialize audio recorder: $e');
      }
      
      _isInitialized = true;
      print('✅ Audio recorder initialized successfully');
    } catch (e) {
      print('❌ Error initializing background service: $e');
      rethrow;
    }
  }

  Future<void> startListening() async {
    print('🎤 Attempting to start listening...');
    
    return _lock.synchronized(() async {
      if (_isListening || _isProcessing || _isStarting) {
        print('⚠️ Already listening, processing, or starting');
        return;
      }

      _isStarting = true;
      try {
        await _audioRecorder.initialize();
        print('✅ Recorder initialized');

        _currentRecordingPath = await _audioRecorder.start();
        print('✅ Recording started at: $_currentRecordingPath');

        _isListening = true;
        _isStarting = false;

        _startDetectionTimer();
        print('✅ Detection timer started');
      } catch (e) {
        print('❌ Error starting listening: $e');
        _isStarting = false;
        _resetStates();
        rethrow;
      }
    });
  }

  Future<void> _startRecordingCycle() async {
    if (!_isListening || _isStopping) {
      print('⚠️ Cannot start recording cycle - listening: $_isListening, stopping: $_isStopping');
      return;
    }

    try {
      // Get the app directory for saving recordings
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${appDir.path}/audio_$timestamp.wav';
      
      print('🎤 Starting new recording cycle at: $path');
      
      // Start recording with proper configuration
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: path,
      );
      
      print('✅ Recording started successfully');

      // Set up timer to stop recording after 5 seconds
      _detectionTimer?.cancel();
      _detectionTimer = Timer(const Duration(seconds: 5), () async {
        if (_isListening && !_isStopping) {
          print('⏱️ 5-second recording duration reached, processing...');
          await _audioRecorder.stop();
          print('✅ Recording stopped for processing');
          await _processRecording(path);
        }
      });
    } catch (e) {
      print('❌ Error in recording cycle: $e');
      _isListening = false;
      _isStopping = false;
      _isProcessing = false;
    }
  }

  Future<void> _processRecording(String path) async {
    if (!_isListening || _isStopping) {
      print('⚠️ Service stopped during processing, aborting.');
      return;
    }

    if (_isProcessing) {
      print('⚠️ Already processing a recording, skipping.');
      return;
    }
    
    _isProcessing = true;
    onProcessingStateChanged?.call(true);

    try {
      print('🔄 Processing recording at: $path');
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Recording file not found');
      }

      final size = await file.length();
      print('📊 Recording size: $size bytes');

      final result = await _soundService.detectSound(path);
      print('✅ Sound detection result received: $result');

      if (result != null) {
        final pushResponse = result['push_response'];
        if (pushResponse != null && pushResponse.isNotEmpty) {
          final parts = pushResponse.split(',');
          if (parts.length >= 3) {
            final detectedLabel = parts[2];
            final confidence = double.tryParse(parts[0]) ?? 0.0;

            await _handleSoundDetection({
              'label': detectedLabel,
              'confidence': confidence,
            });

            if (_isListening && !_isStopping) {
              await _notificationService.showNotification(
                title: 'Sound Detected',
                body: 'Detected: $detectedLabel',
              );
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error processing recording: $e');
      if (_isListening && !_isStopping) {
        await _notificationService.showNotification(
          title: 'Processing Error',
          body: 'An error occurred during sound detection.',
        );
      }
    } finally {
      _isProcessing = false;
      onProcessingStateChanged?.call(false);

      if (_isStopping) {
        print('🛑 Stop was requested during processing, completing stop...');
        try {
          await _audioRecorder.stop();
        } catch (e) {
          print('⚠️ Error stopping recorder during cleanup: $e');
        }
        _resetStates();
        return;
      }
    }
  }

  Future<void> stopListening() async {
    print('🛑 Attempting to stop listening...');
    
    return _lock.synchronized(() async {
      if (!_isListening && !_isProcessing) {
        print('⚠️ Not listening or processing');
        _resetStates();
        return;
      }

      _isStopping = true;

      try {
        _detectionTimer?.cancel();
        _detectionTimer = null;

        if (_isProcessing) {
          print('⏳ Currently processing audio, waiting for completion...');
          onShowMessage?.call('Please wait while processing audio...');
          // Don't return, let it complete the stop operation
        }

        print('⏹️ Stopping audio recorder...');
        await _audioRecorder.stop();
        _currentRecordingPath = null;
        _processingPath = null;

        _resetStates();
        print('✅ Successfully stopped listening');
      } catch (e) {
        print('❌ Error stopping listening: $e');
        _resetStates();
        rethrow;
      }
    });
  }

  void _resetStates() {
    _isListening = false;
    _isProcessing = false;
    _isStopping = false;
    _isStarting = false;
    _currentRecordingPath = null;
    _processingPath = null;
    _detectionTimer?.cancel();
    _detectionTimer = null;
    onProcessingStateChanged?.call(false);
  }

  void _startDetectionTimer() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer(const Duration(seconds: 5), () async {
      if (!_isListening || _isStopping) {
        print('⚠️ Timer triggered but not listening or stopping');
        return;
      }

      if (_currentRecordingPath == null) {
        print('⚠️ No recording path available');
        return;
      }

      try {
        print('⏱️ 5-second recording duration reached, processing...');
        // Store the current path and start a new recording
        _processingPath = _currentRecordingPath;
        _currentRecordingPath = await _audioRecorder.start();
        print('✅ Started new recording at: $_currentRecordingPath');
        
        // Process the previous recording
        if (_processingPath != null) {
          await _processRecording(_processingPath!);
        }
      } catch (e) {
        print('❌ Error in detection timer: $e');
        _resetStates();
      }
    });
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
    if (!_isListening) {
      print('⚠️ Service stopped during detection, aborting.');
      return;
    }

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
          sampleRate: 16000,
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

  Future<void> _handleSoundDetection(Map<String, dynamic> detection) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in, skipping Firestore save');
        return;
      }

      await _firestore.collection('sound_detections').add({
        ...detection,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Successfully saved to Firestore');
    } catch (e) {
      print('❌ Error saving to Firestore: $e');
      rethrow;
    }
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

  Future<void> _saveToFirestore(Map<String, dynamic> result) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in, cannot save to Firestore');
        return;
      }

      await FirebaseFirestore.instance.collection('sound_detections').add({
        'userId': user.uid,
        'label': result['label'],
        'confidence': result['confidence'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Sound detection saved to Firestore');
    } catch (e) {
      print('❌ Error saving to Firestore: $e');
    }
  }

  // Setter for the message callback
  void setMessageCallback(Function(String) callback) {
    onShowMessage = callback;
  }

  void setProcessingCallback(Function(bool) callback) {
    onProcessingStateChanged = callback;
  }
} 