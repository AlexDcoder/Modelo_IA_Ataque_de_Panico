import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static final http.Client client = http.Client();
  static const String baseUrl =
      "https://modelo-ia-ataque-de-panico.onrender.com";
  static const Duration timeoutDuration = Duration(seconds: 630);

  Future<http.Response> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request.timeout(timeoutDuration);
      _logResponse(response);
      return response;
    } catch (e) {
      debugPrint('❌ Network error: $e');
      rethrow;
    }
  }

  void _logResponse(http.Response response) {
    debugPrint('🌐 ${response.statusCode} - ${response.request?.url}');
    if (response.headers.containsKey('location')) {
      debugPrint('➡️ Location: ${response.headers['location']}');
    }
    if (response.statusCode >= 400) {
      debugPrint('❌ Error: ${response.body}');
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = {'Content-Type': 'application/json'};

    final response = await _handleRequest(
      client.post(url, headers: headers, body: jsonEncode(body)),
    );

    if ((response.statusCode == 307 || response.statusCode == 308) &&
        response.headers.containsKey('location')) {
      final location = response.headers['location']!;
      final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
      final redirectedUri =
          location.startsWith('http')
              ? Uri.parse(location)
              : base.resolve(location);

      final redirectedResponse = await client.post(
        redirectedUri,
        headers: headers,
        body: jsonEncode(body),
      );

      return redirectedResponse;
    }

    return response;
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await _handleRequest(client.get(url));
  }

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

  Future<http.Response> authenticatedPost(
    String endpoint,
    Map<String, dynamic> body,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await _handleRequest(
      client.post(url, headers: headers, body: jsonEncode(body)),
    );

    if ((response.statusCode == 307 || response.statusCode == 308) &&
        response.headers.containsKey('location')) {
      final location = response.headers['location']!;
      final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
      final redirectedUri =
          location.startsWith('http')
              ? Uri.parse(location)
              : base.resolve(location);

      final redirectedResponse = await client.post(
        redirectedUri,
        headers: headers,
        body: jsonEncode(body),
      );

      _logResponse(redirectedResponse);
      return redirectedResponse;
    }

    return response;
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
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await _handleRequest(
      client.put(url, headers: headers, body: jsonEncode(body)),
    );

    if ((response.statusCode == 307 || response.statusCode == 308) &&
        response.headers.containsKey('location')) {
      final location = response.headers['location']!;
      final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
      final redirectedUri =
          location.startsWith('http')
              ? Uri.parse(location)
              : base.resolve(location);

      final redirectedResponse = await client.put(
        redirectedUri,
        headers: headers,
        body: jsonEncode(body),
      );

      _logResponse(redirectedResponse);
      return redirectedResponse;
    }

    return response;
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
