import 'dart:convert';
import 'package:http/http.dart' as http;

class SoundService {
  static const String _apiUrl = 'http://16.171.115.187:8000/auth/voice-detect/';

  /// Sends the recorded audio file at [path] to your backend with the user's [token].
  /// Expects a JSON response like { "label": "baby_crying", "confidence": 0.92 }.
  Future<Map<String, dynamic>> detectSound(String path, String token) async {
    final uri = Uri.parse(_apiUrl);
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('audio', path))
      ..fields['token'] = token;

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Sound API error: ${response.statusCode}');
    }
  }
} 