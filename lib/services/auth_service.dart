import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:sound_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:sound_app/services/background_service.dart';
import 'package:sound_app/services/mic_state.dart';

class AuthService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static const String _baseUrl = 'http://13.61.5.249:8000';
  static const String _loginUrl = '$_baseUrl/auth/login/';
  static const String _registerUrl = '$_baseUrl/auth/register/';
  static const String _resetPasswordUrl = '$_baseUrl/auth/reset-password/';
  static const String _userProfileUrl = '$_baseUrl/auth/profile/';
  
  static String? _accessToken;
  static String? _refreshToken;
  static String? _userEmail;
  static DateTime? _tokenExpiry;
  static Map<String, dynamic>? _currentUser;
  int _tokenRefreshCount = 0;  // Track number of token refreshes

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static String? get accessToken => _accessToken;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isLoggedIn => _accessToken != null && _currentUser != null;

  static Future<void> saveTokens(String accessToken, String refreshToken, String email) async {
    print('💾 Saving tokens and email...');
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userEmail = email;
    
    // Decode JWT to get expiry
    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
        _tokenExpiry = expiry;
        print('📅 Token expiry set to: $_tokenExpiry');
      }
    } catch (e) {
      print('⚠️ Error decoding token expiry: $e');
    }

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_email', email);
    if (_tokenExpiry != null) {
      await prefs.setString('token_expiry', _tokenExpiry!.toIso8601String());
    }
    print('✅ Tokens and email saved successfully');
  }

  static Future<void> loadTokens() async {
    print('📂 Loading saved tokens...');
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _userEmail = prefs.getString('user_email');
    final expiryStr = prefs.getString('token_expiry');
    if (expiryStr != null) {
      _tokenExpiry = DateTime.parse(expiryStr);
    }
    print('📊 Loaded state:');
    print('- Has access token: ${_accessToken != null}');
    print('- Has refresh token: ${_refreshToken != null}');
    print('- Has user email: ${_userEmail != null}');
    print('- Token expiry: $_tokenExpiry');
  }

  Future<String?> getAccessToken() async {
    if (_accessToken == null) {
      await AuthService.loadTokens();
    }
    return _accessToken;
  }

  static Future<http.Response> makeAuthenticatedRequest(
    String endpoint,
    String method, {
    Map<String, String>? headers,
    dynamic body,
    bool isMultipart = false,
  }) async {
    print('\n🔐 [AuthService] Starting authenticated request...');
    print('🔑 Using token: ${_accessToken?.substring(0, 10)}...');

    if (_accessToken == null) {
      print('❌ No access token available');
      throw Exception('No access token available');
    }

    // Check if token is expired
    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
      print('⚠️ Token has expired. Logging out user...');
      await handleSessionExpiration();
      throw Exception('Session expired');
    }

    final requestHeaders = {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
      ...?headers,
    };

    print('📤 Making authenticated request...');
    print('URL: ${AppConstants.baseUrl}$endpoint');
    print('Method: $method');
    print('Headers: $requestHeaders');

    try {
      http.Response response;
      if (isMultipart && body is http.MultipartRequest) {
        // Add authorization header to multipart request
        body.headers['Authorization'] = 'Bearer $_accessToken';
        response = await http.Response.fromStream(await body.send());
      } else {
        final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: requestHeaders);
            break;
          case 'POST':
            response = await http.post(uri, headers: requestHeaders, body: body != null ? json.encode(body) : null);
            break;
          case 'PUT':
            response = await http.put(uri, headers: requestHeaders, body: body != null ? json.encode(body) : null);
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: requestHeaders);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }
      }

      print('📥 Response received:');
      print('- Status code: ${response.statusCode}');
      print('- Response body: ${response.body}');

      if (response.statusCode == 401) {
        print('⚠️ Unauthorized response received. Logging out user...');
        await handleSessionExpiration();
        throw Exception('Session expired');
      }

      return response;
    } catch (e) {
      print('❌ Error during authenticated request: $e');
      rethrow;
    }
  }

  static Future<void> handleSessionExpiration() async {
    print('🔄 Handling session expiration...');
    
    // Clear stored tokens
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_email');
    
    // Reset in-memory state
    _accessToken = null;
    _refreshToken = null;
    _userEmail = null;
    _tokenExpiry = null;
    
    // Navigate to login screen using GetX
    await BackgroundService().stopListening();
    micListening.value = false;
    Get.offAllNamed('/login');
    
    // Show a user-friendly message using GetX
    Get.snackbar(
      'Session Expired',
      'Your session has expired. Please log in again.',
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  static Future<void> logout() async {
    // Implementation of logout method
  }

  // Original authenticatedRequest method for backward compatibility
  static Future<http.Response> authenticatedRequest(Future<http.Response> Function(String token) request) async {
    print('\n🔐 [AuthService] Starting authenticated request...');
    
    if (_accessToken == null) {
      await AuthService.loadTokens();
    }

    if (_accessToken == null) {
      print('❌ No access token available after check');
      await handleSessionExpiration();
      throw Exception('No access token available');
    }

    print('\n📤 Making authenticated request...');
    print('🔑 Using token: ${_accessToken!.substring(0, 10)}...');

    try {
      final response = await request(_accessToken!);
      
      print('\n📥 Response received:');
      print('- Status code: ${response.statusCode}');
      print('- Response body: ${response.body}');

      if (response.statusCode == 401) {
        print('⚠️ Unauthorized response received. Logging out user...');
        await handleSessionExpiration();
        throw Exception('Session expired');
      }

      return response;
    } catch (e) {
      print('❌ Error in authenticated request: $e');
      rethrow;
    }
  }

  // Method for MultipartRequest
  Future<http.StreamedResponse> authenticatedRequestMultipart(http.MultipartRequest request) async {
    print('\n🔐 [AuthService] Starting authenticated multipart request...');
    
    String? token = await getAccessToken();
    print('🔑 Using token: ${token?.substring(0, 10)}...');
    
    if (token == null) {
      print('❌ No access token available');
      throw Exception('No access token available');
    }

    request.headers['Authorization'] = 'Bearer $token';
    print('📤 Making authenticated request...');
    print('Authenticated Request URL: ${request.url}');
    print('Authenticated Request Bearer Token: ${token.substring(0, 10)}...');
    print('Multipart Request Fields: ${request.fields}');
    print('Multipart Request Method: ${request.method}');

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('\n📥 Response received:');
      print('- Status code: ${response.statusCode}');
      print('- Response body: $responseBody');

      if (response.statusCode == 401) {
        print('⚠️ Unauthorized response received. Logging out user...');
        await handleSessionExpiration();
        throw Exception('Session expired');
      }

      return http.StreamedResponse(
        Stream.value(utf8.encode(responseBody)),
        response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      print('❌ Error in authenticated request: $e');
      rethrow;
    }
  }

  static Future<void> resetAccount() async {
    print('\n🔄 [AuthService] Resetting account...');
    _accessToken = null;
    _refreshToken = null;
    _userEmail = null;
    _tokenExpiry = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_email');
    await prefs.remove('token_expiry');

    // Stop the microphone when the account is reset
    await BackgroundService().stopListening();

    print('✅ Account reset complete');
    Get.offAllNamed(AppRoutes.login);
    Get.snackbar(
      'Session Expired',
      'Please log in again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFB00020),
      colorText: const Color(0xFFFFFFFF)
    );
  }
} 