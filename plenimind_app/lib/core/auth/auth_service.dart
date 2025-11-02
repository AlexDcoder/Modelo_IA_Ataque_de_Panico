import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_manager.dart';
import 'package:plenimind_app/core/auth/register_data.dart';

class AuthService {
  final String baseUrl = "https://modelo-ia-ataque-de-panico.onrender.com";

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
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
      Uri.parse("$baseUrl/users/me"),
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
      Uri.parse("$baseUrl/auth/refresh"),
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

  Future<void> register(RegisterData data) async {
    final url = Uri.parse("$baseUrl/users/");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Falha ao criar usuário: ${response.body}');
    }
  }
}
