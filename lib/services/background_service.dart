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
  Timer? _recordingTimer;
  bool _isProcessing = false;

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
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 16000,
          ),
          path: testPath,
        );
        
        // Wait a short time to ensure recording starts
        await Future.delayed(const Duration(milliseconds: 500));
        
        await _audioRecorder.stop();
        
        final testFile = File(testPath);
        if (await testFile.exists()) {
          final size = await testFile.length();
          print('📊 Test recording file size: $size bytes');
          await testFile.delete();
        } else {
          print('❌ Test recording file was not created');
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
    print('🎤 Starting to listen...');

    // If already listening or stopping, wait for stop to complete
    if (_isListening || _isStopping) {
      print('⚠️ Already listening or stopping, waiting for stop to complete...');
      await stopListening();
      // Add a small delay to ensure everything is cleaned up
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      // Explicitly check and request microphone permission before starting recorder
      var status = await Permission.microphone.status;
      print('📱 Current microphone permission status before recording: $status');

      if (status.isDenied) {
        print('🔒 Requesting microphone permission before recording...');
        status = await Permission.microphone.request();
        print('📱 New microphone permission status after request: $status');
      }

      if (!status.isGranted) {
        print('❌ Microphone permission not granted, cannot start recording.');
        throw Exception('Microphone permission not granted');
      }

      _startRecordingCycle();
    } catch (e) {
      print('❌ Error starting audio recorder: $e');
      _isListening = false;
      rethrow;
    }
  }

  Future<void> _startRecordingCycle() async {
    if (!_isListening && !_isStopping && !_isProcessing) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${directory.path}/audio_$timestamp.wav';

        print('🎤 Starting new recording cycle at: $path');
        
        // Start the audio recorder with proper configuration
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 128000,
          ),
          path: path,
        );

        _isListening = true;
        print('✅ Recording started successfully');

        // Start a timer to stop the recording after 5 seconds
        _recordingTimer = Timer(const Duration(seconds: 5), () async {
          if (_isListening) {
            print('⏱️ 5-second recording duration reached, processing...');
            await _processRecording(path);
          }
        });
      } catch (e) {
        print('❌ Error in recording cycle: $e');
        _isListening = false;
      }
    }
  }

  Future<void> _processRecording(String path) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Stop the current recording
      await stopListening();
      print('✅ Recording stopped for processing');

      // Process the recording
      print('🔄 Processing recording at: $path');
      final file = File(path);
      if (await file.exists()) {
        final size = await file.length();
        print('📊 Recording size: $size bytes');

        // Send to backend
        print('📡 Sending to backend...');
        final result = await _soundService.detectSound(path);
        
        if (result != null) {
          print('✅ Sound detection result received: $result');
          
          // Save to Firestore
          await _saveToFirestore(result);
          
          // Send notification
          await _notificationService.showNotification(
            title: 'Sound Detected',
            body: 'Detected: ${result['label'] ?? 'Unknown Sound'} (${result['confidence']?.toString() ?? '0'}% confidence)',
          );
          
          print('✅ Processing cycle completed successfully');
        } else {
          print('❌ No result received from backend');
        }
      } else {
        print('❌ Recording file not found at: $path');
      }
    } catch (e) {
      print('❌ Error processing recording: $e');
    } finally {
      _isProcessing = false;
      // Start the next recording cycle
      _startRecordingCycle();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    print('🛑 Attempting to stop listening...');
    _isStopping = true;

    try {
      // Cancel the recording timer if it exists
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Cancel the detection timer
      _detectionTimer?.cancel();
      _detectionTimer = null;

      // Stop the audio recorder
      print('⏹️ Stopping audio recorder...');
      await _audioRecorder.stop();
      _isListening = false;
      print('✅ Recording stopped successfully');
    } catch (e) {
      print('❌ Error stopping recording: $e');
    } finally {
      _isStopping = false;
      print('✅ Stop listening completed successfully');
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
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 16000,
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
} 