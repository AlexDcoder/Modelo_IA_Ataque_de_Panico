import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_manager.dart';
import 'package:plenimind_app/core/auth/register_data.dart';
import 'package:plenimind_app/service/api_client.dart';

class AuthService {
  final ApiClient client = ApiClient();

  Future<bool> login(String email, String password) async {
    final body = {"email": email, "password": password};

    try {
      final http.Response response = await client.post('/auth/login', body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final access = data['access_token'] as String?;
        final refresh = data['refresh_token'] as String?;
        if (access != null && refresh != null) {
          AuthManager().setTokens(access, refresh);
          return true;
        } else {
          print('Resposta inesperada: tokens ausentes. body=${response.body}');
          return false;
        }
      } else {
        print('Erro no login (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao tentar logar: $e');
      return false;
    }
    
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = AuthManager().accessToken;
    if (token == null) return null;

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final http.Response response = await client.get('/users/me', headers: headers);

      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) return await getCurrentUser();
        return null;
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      print('Erro ao buscar usuário (${response.statusCode}): ${response.body}');
      return null;
    } catch (e) {
      print('Exceção ao buscar usuário: $e');
      return null;
    }
  }

  Future<bool> _refreshToken() async {
    final refresh = AuthManager().refreshToken;
    if (refresh == null) return false;

    final body = {"refresh_token": refresh};

    try {
      final http.Response response = await client.post('/auth/refresh', body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final newAccess = data['access_token'];
        if (newAccess != null) {
          AuthManager().accessToken = newAccess;
          return true;
        }
      }

      print('Erro ao renovar token (${response.statusCode}): ${response.body}');
      AuthManager().clearTokens();
      return false;
    } catch (e) {
      print('Exceção ao renovar token: $e');
      return false;
    }
  }

  Future<void> register(RegisterData data) async {
    final body = data.toJson();

    try {
      final http.Response response = await client.post('/users', body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Falha ao criar usuário: ${response.body}');
      }
    } catch (e) {
      print('Exceção ao registrar usuário: $e');
      rethrow;
    }
  }
  
}
