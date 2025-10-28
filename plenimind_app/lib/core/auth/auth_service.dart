import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_manager.dart';

class AuthService {
  final String baseUrl = "localhost:8080//";

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      AuthManager().setTokens(data["access_token"], data["refresh_token"]);
      return true;
    } else {
      print("Erro no login: ${response.body}");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = AuthManager().accessToken;
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/me"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) return await getCurrentUser();
      return null;
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    print("Erro ao buscar usuário: ${response.body}");
    return null;
  }

  Future<bool> _refreshToken() async {
    final refresh = AuthManager().refreshToken;
    if (refresh == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/refresh"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"refresh_token": refresh}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      AuthManager().accessToken = data["access_token"];
      return true;
    }

    print("Erro ao renovar token: ${response.body}");
    AuthManager().clearTokens();
    return false;
  }
}
