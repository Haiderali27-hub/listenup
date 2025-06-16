import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sound_app/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import '../utils/constants.dart';

class SoundService {
  static const String _apiUrl = 'http://13.61.5.249:8000/auth/voice-detect/';
  static const String _registerUrl = 'http://13.61.5.249:8000/auth/register/';
  static const String _loginUrl = 'http://13.61.5.249:8000/auth/login/';
  final Connectivity _connectivity = Connectivity();
  String? _backendToken;
  DateTime? _tokenExpiry;
  int _tokenRefreshCount = 0;  // Track number of token refreshes
  final AuthService _authService = AuthService();

  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  Future<String> _getBackendToken() async {
    // Check if we have a valid token
    if (_backendToken != null && _tokenExpiry != null) {
      final timeUntilExpiry = _tokenExpiry!.difference(DateTime.now());
      if (timeUntilExpiry.isNegative) {
        print('\n🔄 Token has expired (${timeUntilExpiry.inMinutes} minutes ago)');
        print('📊 Token refresh count: ${_tokenRefreshCount + 1}');
        _tokenRefreshCount++;
      } else if (timeUntilExpiry.inMinutes < 5) {
        print('\n⚠️ Token will expire soon (in ${timeUntilExpiry.inMinutes} minutes)');
        print('🔄 Proactively refreshing token...');
        print('📊 Token refresh count: ${_tokenRefreshCount + 1}');
        _tokenRefreshCount++;
      } else {
        print('\n✅ Using cached backend token');
        print('⏰ Token expires in: ${timeUntilExpiry.inMinutes} minutes');
        return _backendToken!;
      }
    } else {
      print('\n🔄 No valid token found, getting new token...');
      print('📊 Token refresh count: ${_tokenRefreshCount + 1}');
      _tokenRefreshCount++;
    }

    print('\n🔄 Starting backend authentication process...');

    try {
      // First try to login with existing account
      print('\n🔑 Attempting to login to backend...');
      final loginResponse = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // 'email': user.email,
          // 'password': user.uid,
        }),
      );

      print('📡 Login response status: ${loginResponse.statusCode}');
      print('📦 Login response body: ${loginResponse.body}');

      if (loginResponse.statusCode == 200) {
        // Login successful
        try {
          final data = jsonDecode(loginResponse.body) as Map<String, dynamic>;
          if (!data.containsKey('access_token')) {
            print('❌ No access_token in response: $data');
            throw Exception('Invalid response format: missing access_token');
          }
          _backendToken = data['access_token'];
          _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
          print('✅ Successfully refreshed token');
          print('⏰ New token expires at: $_tokenExpiry');
          return _backendToken!;
        } catch (e) {
          print('❌ Error parsing login response: $e');
          throw Exception('Invalid login response format: $e');
        }
      } else if (loginResponse.statusCode == 401) {
        print('\n⚠️ Login failed, token might be invalid');
        print('🔄 Attempting to create new account...');
        
        // Account doesn't exist, create new account
        print('\n📝 Creating new backend account...');
        final registerResponse = await http.post(
          Uri.parse(_registerUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            // 'email': user.email,
            // 'password': user.uid,
            'fullname': 'User',
          }),
        );

        print('📡 Registration response status: ${registerResponse.statusCode}');
        print('📦 Registration response body: ${registerResponse.body}');

        if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
          print('✅ Successfully created backend account');
          
          // Registration successful, try login again
          print('\n🔑 Attempting to login with new account...');
          final newLoginResponse = await http.post(
            Uri.parse(_loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              // 'email': user.email,
              // 'password': user.uid,
            }),
          );

          print('📡 New login response status: ${newLoginResponse.statusCode}');
          print('📦 New login response body: ${newLoginResponse.body}');

          if (newLoginResponse.statusCode == 200) {
            try {
              final data = jsonDecode(newLoginResponse.body) as Map<String, dynamic>;
              if (!data.containsKey('access_token')) {
                print('❌ No access_token in response: $data');
                throw Exception('Invalid response format: missing access_token');
              }
              _backendToken = data['access_token'];
              _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
              print('✅ Successfully got new token');
              print('⏰ New token expires at: $_tokenExpiry');
              return _backendToken!;
            } catch (e) {
              print('❌ Error parsing new login response: $e');
              throw Exception('Invalid new login response format: $e');
            }
          } else {
            print('❌ Failed to login after registration. Status: ${newLoginResponse.statusCode}');
            throw Exception('Failed to login after registration: ${newLoginResponse.body}');
          }
        } else {
          print('❌ Failed to create backend account. Status: ${registerResponse.statusCode}');
          throw Exception('Failed to create backend account: ${registerResponse.body}');
        }
      } else {
        print('❌ Unexpected login response status: ${loginResponse.statusCode}');
        throw Exception('Unexpected login response: ${loginResponse.body}');
      }
    } catch (e) {
      print('❌ Error in _getBackendToken: $e');
      rethrow;
    }
  }

  /// Sends the recorded audio file at [path] to your backend.
  /// Includes the user's Access Token (Bearer) and FCM token in the request.
  Future<Map<String, dynamic>> detectSound(String audioPath) async {
    print('\n--- Sound Detection API Call Started ---');
    print('API URL: ${AppConstants.baseUrl}${AppConstants.soundDetectionEndpoint}');
    print('Audio file path: $audioPath');

    // Check connectivity first
    if (!await _checkConnectivity()) {
      print('❌ No internet connection available');
      throw Exception('No internet connection available');
    }

    // Get FCM token
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token being sent to backend: $fcmToken');
    print('FCM Token Format Analysis:');
    if (fcmToken != null) {
      final parts = fcmToken.split(':');
      print('  - Length: ${fcmToken.length} characters');
      print('  - Prefix: ${parts[0]}');
      print('  - Suffix: ${parts[1]}');
      print('  - Valid Format: ${parts[0].startsWith('eG7DuctCTI') ? 'Yes' : 'No'}');
    }

    // Get access token
    String? accessToken = await _authService.getAccessToken();
    print('Access token: ${accessToken?.substring(0, 10)}...');

    // Verify audio file exists
    File audioFile = File(audioPath);
    bool fileExists = await audioFile.exists();
    print('Audio file exists: $fileExists');
    if (fileExists) {
      print('Audio file size: ${await audioFile.length()} bytes');
    }

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}${AppConstants.soundDetectionEndpoint}'),
      );

      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioPath,
        ),
      );

      // Add FCM token
      if (fcmToken != null) {
        request.fields['token'] = fcmToken;
        print('Added FCM token to request fields: ${fcmToken.substring(0, 10)}...');
      }

      // Add authorization header
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
        print('Added Authorization header with token: ${accessToken.substring(0, 10)}...');
      }

      print('\nMaking authenticated request...');
      var streamedResponse = await _authService.authenticatedRequestMultipart(request);
      var response = await http.Response.fromStream(streamedResponse);

      print('\nResponse received:');
      print('- Status code: ${response.statusCode}');
      print('- Response body: ${response.body}');
      print('--- Sound Detection API Call Finished ---\n');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('Successfully parsed response: $responseData');
        print('--- Sound Detection API Call Completed Successfully ---\n');
        return responseData;
      } else {
        print('Error response from server: ${response.body}');
        throw Exception('Failed to detect sound: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in detectSound: $e');
      rethrow;
    }
  }
} 