import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static final http.Client client = http.Client();
  static const String baseUrl = "http://127.0.0.1:8000";
  static const Duration timeoutDuration = Duration(seconds: 30);

  Future<http.Response> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request.timeout(timeoutDuration);
      _logResponse(response);
      return response; // ✅ Returns value
    } catch (e) {
      print('❌ Network error: $e');
      rethrow;
    }
  }

  void _logResponse(http.Response response) {
    print('🌐 ${response.statusCode} - ${response.request?.url}');
    if (response.statusCode >= 400) {
      print('❌ Error: ${response.body}');
    }
  }

  // Métodos públicos sem autenticação
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await _handleRequest(
      client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await _handleRequest(client.get(url));
  }

  // ✅ ADICIONADO: Método PUT sem autenticação (se necessário)
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await _handleRequest(
      client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
  }

  // Métodos autenticados
  Future<http.Response> authenticatedPost(
    String endpoint,
    Map<String, dynamic> body,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await _handleRequest(
      client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> authenticatedGet(String endpoint, String token) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await _handleRequest(
      client.get(url, headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<http.Response> authenticatedPut(
    String endpoint,
    Map<String, dynamic> body,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await _handleRequest(
      client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> authenticatedDelete(
    String endpoint,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await _handleRequest(
      client.delete(url, headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
