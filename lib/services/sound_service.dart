import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class SoundService {
  static const String _apiUrl = 'http://13.61.5.249:8000/auth/voice-detect/';
  static const String _registerUrl = 'http://13.61.5.249:8000/auth/register/';
  static const String _loginUrl = 'http://13.61.5.249:8000/auth/login/';
  final Connectivity _connectivity = Connectivity();
  String? _backendToken;
  DateTime? _tokenExpiry;
  int _tokenRefreshCount = 0;  // Track number of token refreshes

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
  /// Automatically includes the user's Access Token and FCM token in the Authorization header and body.
  /// Expects a JSON response like { "label": "baby_crying", "confidence": 0.92 }.
  Future<Map<String, dynamic>> detectSound(String path, {int retries = 3}) async {
    print('\n--- Sound Detection API Call Started ---');
    print('API URL: $_apiUrl');
    print('Audio file path: $path');

    // Check connectivity first
    if (!await _checkConnectivity()) {
      print('❌ No internet connection available');
      throw Exception('No internet connection available');
    }

    // Get backend token
    print('Getting backend token...');
    final backendToken = await _getBackendToken();
    print('✅ Got backend token: ${backendToken.substring(0, 10)}...');

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        print('\n🔄 Attempt $attempt of $retries');
        
        final uri = Uri.parse(_apiUrl);
        print('📤 Creating multipart request...');
        final request = http.MultipartRequest('POST', uri)
          ..files.add(await http.MultipartFile.fromPath('audio', path))
          ..fields['token'] = 'fcmToken'
          ..headers['Content-Type'] = 'multipart/form-data'
          ..headers['Authorization'] = 'Bearer $backendToken';

        print('📤 Request created with:');
        print('- File: audio');
        print('- FCM token field: token');
        print('- Content-Type: multipart/form-data');
        print('- Authorization header: Bearer token present');

        print('📤 Sending request to server...');
        final streamed = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('❌ Request timed out after 30 seconds');
            throw TimeoutException('Request timed out');
          },
        );
        
        print('⏳ Request sent, waiting for response...');
        final response = await http.Response.fromStream(streamed).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('❌ Response timed out after 30 seconds');
            throw TimeoutException('Response timed out');
          },
        );
        
        print('📥 Response received:');
        print('- Status code: ${response.statusCode}');
        print('- Response headers: ${response.headers}');
        print('- Response body: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            print('✅ Successfully parsed response: $data');
            print('--- Sound Detection API Call Completed Successfully ---\n');
            return data;
          } catch (e) {
            print('❌ Error parsing response JSON: $e');
            print('📦 Raw response body: ${response.body}');
            throw Exception('Invalid JSON response from server: ${response.body}');
          }
        } else if (response.statusCode == 401) {
          print('🔑 Authentication failed, refreshing token...');
          // Clear the token to force a new login
          _backendToken = null;
          _tokenExpiry = null;
          if (attempt == retries) {
            print('❌ Authentication failed after $retries attempts');
            throw Exception('Authentication failed after $retries attempts. Status: ${response.statusCode}, Body: ${response.body}');
          }
          print('🔄 Retrying with new token...');
          continue;
        } else {
          print('❌ Server error: ${response.body}');
          if (attempt == retries) {
            print('❌ Failed after $retries attempts');
            throw Exception('Sound API error: ${response.statusCode} - ${response.body}');
          }
          print('⏳ Waiting before retry...');
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
      } on TimeoutException {
        print('❌ Request timed out on attempt $attempt');
        if (attempt == retries) {
          print('❌ Sound Detection API Call Failed with Timeout ---\n');
          rethrow;
        }
        print('⏳ Waiting before retry...');
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        print('❌ Error in detectSound (attempt $attempt): $e');
        if (attempt == retries) {
          print('❌ Sound Detection API Call Failed with Error ---\n');
          rethrow;
        }
        print('⏳ Waiting before retry...');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    throw Exception('Failed after $retries attempts');
  }
} 