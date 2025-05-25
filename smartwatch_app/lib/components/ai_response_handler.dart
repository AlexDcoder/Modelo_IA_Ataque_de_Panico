import 'dart:convert';
import 'package:http/http.dart' as http;

class AIResponseHandler {
  final String baseUrl;
  final String uid;

  AIResponseHandler({required this.baseUrl, required this.uid});

  Future<String?> fetchAIPrediction() async {
    final url = Uri.parse('$baseUrl/server/users/$uid/ai-response');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonResp = jsonDecode(response.body);
      return jsonResp['ai_prediction'].toString();
    }
    return null;
  }

  Future<bool> sendFeedback(Map<String, dynamic> features, int feedback) async {
    final url = Uri.parse('$baseUrl/server/users/$uid/feedback');
    final body = jsonEncode({
      "uid": uid,
      "features": features,
      "user_feedback": feedback,
    });
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    return response.statusCode == 200;
  }
}
