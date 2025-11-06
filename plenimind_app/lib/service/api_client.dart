import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static final http.Client client = http.Client();
  static const String baseUrl = "https://modelo-ia-ataque-de-panico.onrender.com";

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    final defaultHeaders = {'Content-Type': 'application/json'};
    final mergedHeaders = {...defaultHeaders, if (headers != null) ...headers};
    
    try {
      final response = await client.post(
        url,
        headers: mergedHeaders,
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    final defaultHeaders = {'Accept': 'application/json'};
    final mergedHeaders = {...defaultHeaders, if (headers != null) ...headers};

    try {
      final response = await client.get(url, headers: mergedHeaders);
      return response;
    } catch (e) {
      rethrow;
    }
  }

}
