import 'dart:convert';
import 'package:http/http.dart' as http;

class SoundService {
  /// Sends the recorded audio file at [path] to your backend.
  /// Expects a JSON response like { "label": "baby_crying", "confidence": 0.92 }.
  Future<Map<String, dynamic>> detectSound(String path) async {
    final uri = Uri.parse('https://your-api.com/detect');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Sound API error: ${response.statusCode}');
    }
  }
}
