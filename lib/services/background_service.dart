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

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final SoundService _soundService = SoundService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _baseUrl = 'http://16.171.115.187:8000';
  Timer? _detectionTimer;
  bool _isInitialized = false;
  bool _isListening = false;
  String? _lastRecordedFilePath;
  bool _isStopping = false;

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

    if (!_isInitialized) {
      print('🔄 Not initialized, initializing now...');
      await initialize();
    }

    try {
      print('🎤 Starting audio recorder (using record package)...');
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      final recordConfig = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 48000,
        numChannels: 1,
      );

      await _audioRecorder.start(recordConfig, path: filePath);
      
      _isListening = true;
      print('✅ Audio recorder started successfully (using record package)');
      print('📁 Recording to file: $filePath');

      print('⏱️ Setting up detection timer...');
      _detectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!_isListening || _isStopping) {
          print('⚠️ Not listening or stopping, cancelling timer...');
          timer.cancel();
          return;
        }

        try {
          await Future.delayed(const Duration(milliseconds: 500));
          
          print('⏹️ Stopping recorder to get audio file...');
          final path = await _audioRecorder.stop();
          if (path != null) {
            _lastRecordedFilePath = path;
            print('📁 Got audio file at: $path');
            
            final file = File(path);
            if (await file.exists()) {
              final fileSize = await file.length();
              print('📊 Audio file size: ${fileSize} bytes');
              if (fileSize <= 44) {
                print('⚠️ Warning: Audio file is suspiciously small or empty!');
                print('   Expected size > 44 bytes for 5 seconds of audio');
                print('   Current size: $fileSize bytes');
                print('   File path: $path');
                
                try {
                  final bytes = await file.readAsBytes();
                  print('📝 First 100 bytes of file: ${bytes.take(100).toList()}');
                } catch (e) {
                  print('❌ Error reading file content: $e');
                }
              }
            } else {
              print('❌ Error: Audio file does not exist!');
            }

            final user = _auth.currentUser;
            if (user == null) {
              print('⚠️ No user logged in, skipping detection');
              return;
            }
            print('📡 Calling sound detection service...');
            final result = await _soundService.detectSound(path);
            print('📥 API result received: $result');

            final pushResponse = result['push_response'];
            if (pushResponse != null && pushResponse.isNotEmpty) {
              print('🔄 Processing push_response: $pushResponse');
              final parts = pushResponse.split(',');
              if (parts.length >= 2) {
                final confidence = double.tryParse(parts[0]);
                final label = parts[1];
                print('📊 Parsed confidence: $confidence, label: $label');

                if (confidence != null && confidence > 0.7) {
                  print('✅ High confidence detection! Saving to Firestore...');
                  await _handleSoundDetection({'label': label, 'confidence': confidence});
                } else {
                  print('⚠️ Confidence too low ($confidence), not saving.');
                }
              } else {
                print('⚠️ Unexpected push_response format: $pushResponse');
              }
            } else {
              print('⚠️ push_response is null or empty');
            }
          } else {
            print('❌ No audio file path received');
          }
          final newFilePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
          print('🎤 Restarting audio recorder (using record package)...');
          final newRecordConfig = RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 48000,
            numChannels: 1,
          );
          await _audioRecorder.start(newRecordConfig, path: newFilePath);
          print('✅ Audio recorder restarted');
        } catch (e) {
          print('❌ Error in sound detection cycle: $e');
          print('Stack trace: ${StackTrace.current}');
        }
        print('🔄 --- Detection Cycle Ended ---\n');
      });
      print('✅ Detection timer setup complete');
    } catch (e) {
      print('❌ Error starting recording: $e');
      rethrow;
    }
  }

  Future<void> stopListening() async {
    if (_isStopping) {
      print('⚠️ Already in the process of stopping, ignoring duplicate stop request');
      return;
    }

    print('🛑 Attempting to stop listening...');
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
        await _audioRecorder.stop();
        _isListening = false;
        print('✅ Recording stopped successfully');
      } else {
        print('ℹ️ Recorder was not active');
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      // Reset state even if there's an error
      _isListening = false;
      _detectionTimer?.cancel();
      _detectionTimer = null;
    } finally {
      _isStopping = false;
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