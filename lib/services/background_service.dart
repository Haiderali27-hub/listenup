import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sound_app/services/notification_service.dart';
import 'package:sound_app/services/sound_service.dart';
import 'package:synchronized/synchronized.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  AudioRecorder? _audioRecorder;
  final SoundService _soundService = SoundService();
  final NotificationService _notificationService = NotificationService();
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
  String? _processingPath;

  Future<void> initialize() async {
    await _lock.synchronized(() async {
      print('🔒 Lock acquired for initialize(). _isInitialized: $_isInitialized, _audioRecorder is null: ${_audioRecorder == null}');
      if (_isInitialized && _audioRecorder != null) {
        print('✅ BackgroundService already initialized. Exiting initialize().');
        return;
      }

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
          throw Exception(
              'Microphone permission not granted. Current status: $status');
        }

        // Initialize recorder only if it's null
        if (_audioRecorder == null) {
          print('🆕 Initializing AudioRecorder instance.');
          _audioRecorder = AudioRecorder();
        }
        
        // Verify recorder permission
        print('🔍 Verifying audio recorder permission...');
        final hasPermission = await _audioRecorder!.hasPermission();
        print('📱 Audio recorder permission status: $hasPermission');

        if (!hasPermission) {
          throw Exception('Audio recorder permission not granted');
        }

        _isInitialized = true;
        print('✅ Audio recorder initialized successfully');
      } catch (e) {
        print('❌ Error initializing background service: $e');
        // If an error occurs, ensure _audioRecorder is reset for a fresh attempt
        if (_audioRecorder != null) {
          print('🗑️ Disposing and nulling _audioRecorder due to initialization error.');
          await _audioRecorder!.dispose(); // Dispose if it was initialized
          _audioRecorder = null; // Set to null
        }
        _isInitialized = false; // Ensure isInitialized is false
        rethrow;
      } finally {
        print('🔓 Lock released for initialize().');
      }
    });
  }

  Future<void> startListening() async {
    print('🎤 startListening() called. _isListening: $_isListening, _isInitialized: $_isInitialized, _audioRecorder is null: ${_audioRecorder == null}');

    if (!_isInitialized || _audioRecorder == null) {
      print('❌ Error: BackgroundService not initialized or recorder is null. Exiting startListening().');
      onShowMessage?.call('Error: Microphone service not ready.');
      return;
    }

    try {
      print('🎤 Attempting to start recording segment...');
      
      // Get the application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      
      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _lastRecordedFilePath = '${appDir.path}/temp_recording_$timestamp.wav';
      
      print('📁 Using app directory: ${appDir.path}');
      print('📁 Recording path: $_lastRecordedFilePath');

      // Ensure recorder is not already recording before starting a new segment
      if (await _audioRecorder!.isRecording()) {
        print('⚠️ Audio recorder already recording. Stopping current segment before starting new one.');
        await _audioRecorder!.stop();
      }

      // Start recording
      if (_lastRecordedFilePath != null) {
        // Set _isListening to true here as the overall intent is to listen continuously
        _isListening = true;

        await _audioRecorder!.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 128000,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: _lastRecordedFilePath!,
        );

        print('✅ Recording started at: $_lastRecordedFilePath');

        // Start a timer to stop recording segment and process after _recordingDuration
        _recordingTimer = Timer(_recordingDuration, () async {
          print('⏱️ Recording timer fired. _isListening: $_isListening');
          if (_isListening) { // Check _isListening again to ensure user hasn't stopped it externally
            print('⏱️ Recording duration reached, stopping segment and processing...');
            await _stopRecordingSegment(); // Stop current segment, but keep overall listening state true
            await _processRecording(); // Process it
          } else {
            print('⏱️ Recording timer fired, but _isListening is false. Not processing/restarting.');
          }
        });
        print('✅ Recording timer started for $_recordingDuration');

      } else {
        throw Exception('Failed to create recording path');
      }

    } catch (e) {
      print('❌ Error starting recording: $e');
      _isListening = false; // Ensure it's false if start fails
      onShowMessage?.call('Failed to start recording: ${e.toString()}');
    }
  }

  Future<void> _processRecording() async {
    print('🔄 _processRecording() called. _isListening: $_isListening');

    if (_lastRecordedFilePath == null) {
      print('❌ No recording file path available');
      // If no file path, and we are supposed to be listening, attempt to restart clean
      if (_isListening) {
        print('Attempting to restart listening due to missing file path.');
        await Future.delayed(const Duration(milliseconds: 500));
        startListening();
      }
      return;
    }

    try {
      print('🔄 Processing recording at: $_lastRecordedFilePath');
      
      // Check if file exists and get its size
      final file = File(_lastRecordedFilePath!);
      if (await file.exists()) {
        final size = await file.length();
        print('📊 Recording size: $size bytes');
        
        if (size == 0) {
          print('❌ Recording file is empty');
          onShowMessage?.call('Recording failed: Empty file');
          // If empty, and listening, attempt to restart clean
          if (_isListening) {
            print('Attempting to restart listening due to empty file.');
            await Future.delayed(const Duration(milliseconds: 500));
            startListening();
          }
          return;
        }
      } else {
        print('❌ Recording file does not exist');
        onShowMessage?.call('Recording failed: File not found');
        // If file missing, and listening, attempt to restart clean
        if (_isListening) {
          print('Attempting to restart listening due to missing file.');
          await Future.delayed(const Duration(milliseconds: 500));
          startListening();
        }
        return;
      }

      // Process the recording
      onProcessingStateChanged?.call(true);

      print('📤 Sending audio to sound service...');
      final result = await _soundService.detectSound(_lastRecordedFilePath!);
      print('📥 Sound service response received.');

      onProcessingStateChanged?.call(false);

      if (result != null && result['push_response'] != null) {
        final pushResponse = result['push_response'] as String;
        final parts = pushResponse.split(',');
        String label = 'Unknown';
        if (parts.length >= 3) {
          label = parts[2]; // Assuming the label is the third part
        }

        print('✅ Sound detected: $label');
        
        onShowMessage?.call('Detected: $label');

        // Removed: Show a local notification - relying on backend push notifications
        // _notificationService.showNotification(
        //   title: 'Sound Detected!',
        //   body: 'A sound was detected: $label',
        // );
        print('✅ Notification triggered for: $label');

        // Restart listening for the next segment if still active
        if (_isListening) {
          print('🔄 Re-starting recording cycle. Calling startListening()...');
          startListening();
        } else {
          print('🛑 _isListening is false. Not re-starting recording cycle.');
        }
      } else {
        print('❌ No sound detected or invalid response format from backend.');
        onShowMessage?.call('No sound detected');
      }
    } catch (e) {
      print('❌ Error processing recording: $e');
      onProcessingStateChanged?.call(false);
      onShowMessage?.call('Error processing recording: ${e.toString()}');
      // On error, if still listening, attempt to restart clean
      if (_isListening) {
        print('Attempting to restart listening after processing error.');
        await Future.delayed(const Duration(milliseconds: 500));
        startListening();
      }
    } finally {
      // Clean up the temporary file
      try {
        if (_lastRecordedFilePath != null) {
          final file = File(_lastRecordedFilePath!);
          if (await file.exists()) {
            await file.delete();
            print('🗑️ Temporary recording file deleted: $_lastRecordedFilePath');
          }
        }
      } catch (e) {
        print('⚠️ Error cleaning up temporary file: $e');
      } finally {
        // After processing, if still listening, restart the recording cycle
        if (_isListening) {
          print('🔄 Re-starting recording cycle. Calling startListening()...');
          // Add a small delay to prevent rapid re-starts
          await Future.delayed(const Duration(milliseconds: 500));
          startListening();
        } else {
          print('🛑 _isListening is false. Not re-starting recording cycle.');
        }
      }
    }
  }

  // New method to stop just the current recording segment
  Future<void> _stopRecordingSegment() async {
    print('🛑 _stopRecordingSegment() called. _isInitialized: $_isInitialized, _audioRecorder is null: ${_audioRecorder == null}');
    if (!(_isInitialized && _audioRecorder != null)) {
      print('⚠️ Not initialized/recorder null. Cannot stop segment.');
      return; // Should already be initialized
    }

    try {
      if (await _audioRecorder!.isRecording()) {
        await _audioRecorder!.stop();
        print('✅ Current recording segment stopped');
      } else {
        print('ℹ️ Audio recorder not recording. No segment to stop.');
      }
    } catch (e) {
      print('❌ Error stopping recording segment: $e');
      // Don't set _isListening = false here, as the overall intent might be to continue
    }
  }

  // Public method to stop all listening (user initiated)
  Future<void> stopListening() async {
    print('🛑 stopListening() called (public). _isListening: $_isListening');
    if (!_isListening) {
      print('ℹ️ Already not listening. Exiting public stopListening().');
      return;
    }

    try {
      print('🛑 Stopping all listening...');
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _isListening = false; // THIS IS THE ONLY PLACE _isListening BECOMES FALSE FOR USER STOP

      if (_isInitialized && _audioRecorder != null) {
        print('Stopping audio recorder for full stop.');
        await _audioRecorder!.stop();
        print('✅ All recording stopped');
      } else {
        print('⚠️ Recorder not initialized or null during full stop.');
      }
    } catch (e) {
      print('❌ Error stopping all listening: $e');
      // Keep _isListening state as is, depending on the error context
      onShowMessage?.call('Failed to stop listening: ${e.toString()}');
    } finally {
      print('💡 _isListening is now $_isListening.');
    }
  }

  @override
  Future<void> dispose() async {
    print('🔌 dispose() called. Attempting to stop listening and dispose recorder.');
    await stopListening();
    if (_isInitialized && _audioRecorder != null) {
      await _audioRecorder!.dispose();
      _audioRecorder = null;
      _isInitialized = false;
      print('🔌 Audio recorder disposed');
    } else {
      print('ℹ️ No active recorder to dispose.');
    }
  }

  bool get isListening => _isListening;
  String? get lastRecordedFilePath => _lastRecordedFilePath;

  void setMessageCallback(Function(String) callback) {
    onShowMessage = callback;
  }

  void setProcessingCallback(Function(bool) callback) {
    onProcessingStateChanged = callback;
  }
}

class BackendAuthService {
  static const String _baseUrl = 'http://13.61.5.249:8000';
  static const String _registerUrl = '$_baseUrl/auth/register/';
  static const String _loginUrl = '$_baseUrl/auth/login/';
  static const String _resetPasswordUrl = '$_baseUrl/auth/reset-password/';
  static const String _userProfileUrl = '$_baseUrl/auth/profile/';
  
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  Map<String, dynamic>? _currentUser;

  // Singleton pattern
  static final BackendAuthService _instance = BackendAuthService._internal();
  factory BackendAuthService() => _instance;
  BackendAuthService._internal();

  String? get accessToken => _accessToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _accessToken != null && _currentUser != null;

  Future<Map<String, dynamic>?> registerWithEmailAndPassword(
    String email, 
    String password, 
    String fullname
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullname': fullname,
        }),
      );

      print('📡 Register response status: ${response.statusCode}');
      print('📦 Register response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // After successful registration, automatically login
        final loginResult = await signInWithEmailAndPassword(email, password);
        if (loginResult != null) {
          Get.snackbar(
            'Success',
            'Account created successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Get.offAllNamed(AppRoutes.home);
        }
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        String message = 'Registration failed';
        if (errorData['detail'] != null) {
          message = errorData['detail'];
        } else if (errorData['email'] != null) {
          message = 'Email: ${errorData['email'][0]}';
        }
        
        Get.snackbar(
          'Registration Failed',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }
    } catch (e) {
      print('❌ Error in registration: $e');
      Get.snackbar(
        'Registration Failed',
        'Network error. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 Login response status: ${response.statusCode}');
      print('📦 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        
        // Get user profile
        await _fetchUserProfile();
        
        Get.snackbar(
          'Success',
          'Welcome back!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        Get.offAllNamed(AppRoutes.home);
        return _currentUser;
      } else {
        final errorData = jsonDecode(response.body);
        String message = 'Login failed';
        if (errorData['detail'] != null) {
          message = errorData['detail'];
        }
        
        Get.snackbar(
          'Login Failed',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }
    } catch (e) {
      print('❌ Error in login: $e');
      Get.snackbar(
        'Login Failed',
        'Network error. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<void> _fetchUserProfile() async {
    if (_accessToken == null) return;
    
    try {
      final response = await http.get(
        Uri.parse(_userProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        _currentUser = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ User profile fetched: ${_currentUser!['email']}');
      }
    } catch (e) {
      print('❌ Error fetching user profile: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse(_resetPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Password reset link has been sent to your email',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        final errorData = jsonDecode(response.body);
        Get.snackbar(
          'Error',
          errorData['detail'] ?? 'Failed to send reset email',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Error sending reset email: $e');
      Get.snackbar(
        'Error',
        'Network error. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> signOut() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _currentUser = null;

    Get.offAllNamed(AppRoutes.login);
  }

  Future<String?> refreshAccessToken() async {
    if (_refreshToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _accessToken = data['access'];
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        return _accessToken;
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
    }
    
    return null;
  }
}
