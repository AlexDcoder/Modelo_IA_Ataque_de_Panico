import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static final http.Client client = http.Client();
  static const String baseUrl = "http://127.0.0.1:8000/server";

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await client.get(url);
    return response;
  }
}
