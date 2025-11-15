import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/service/api_client.dart';
import 'package:plenimind_app/schemas/request/personal_data.dart';
import 'package:plenimind_app/schemas/response/user_personal_request.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();
  final AuthManager _authManager = AuthManager();

  // GET /users/ → Lista todos usuários (admin)
  Future<Map<String, dynamic>?> getAllUsers() async {
    try {
      final token = _authManager.token;
      if (token == null) {
        debugPrint('❌ Nenhum token disponível para getAllUsers');
        return null;
      }

      final response = await _apiClient.authenticatedGet('users', token);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
          '❌ Get all users failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Get all users error: $e');
      return null;
    }
  }

  // ✅ NOVO: GET /users/me → Dados do usuário atual
  Future<UserPersonalDataResponse?> getCurrentUser() async {
    try {
      debugPrint('🐤 Buscando usuário atual...');

      final token = _authManager.token;
      if (token == null) {
        debugPrint('❌ getCurrentUser: Token NULO no AuthManager');
        return null;
      }

      debugPrint(
        '✅ getCurrentUser: Token disponível (${token.substring(0, 20)}...)',
      );

      final response = await _apiClient.authenticatedGet('users/me', token);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final userResponse = UserPersonalDataResponse.fromJson(json);

        debugPrint('✅ Rota /me funcionou - UserId: ${userResponse.uid}');
        return userResponse;
      } else {
        debugPrint(
          '❌ getCurrentUser failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ getCurrentUser error: $e');
      return null;
    }
  }

  // GET /users/{uid} → Dados públicos de usuário
  Future<UserPersonalDataResponse?> getUserPublic(String uid) async {
    try {
      final token = _authManager.token;
      if (token == null) {
        debugPrint('❌ Nenhum token disponível para getUserPublic');
        return null;
      }

      final response = await _apiClient.authenticatedGet('users/$uid', token);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return UserPersonalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ Get user public failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Get user public error: $e');
      return null;
    }
  }

  // POST /users/ → Cria novo usuário
  Future<UserPersonalDataResponse?> createUser(UserPersonalData user) async {
    try {
      debugPrint('🐤 Criando usuário: ${user.email}');

      final response = await _apiClient.post('users', user.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);

        // 📌 OPÇÃO C: Log detalhado da resposta completa
        debugPrint('📤 [CREATE_USER] Response Status: ${response.statusCode}');
        debugPrint('📤 [CREATE_USER] Response Headers: ${response.headers}');
        debugPrint('📤 [CREATE_USER] Response Body Completo: ${response.body}');
        debugPrint('📤 [CREATE_USER] Parsed JSON: $json');

        // Verificar se há tokens na resposta
        if (json.containsKey('access_token') || json.containsKey('token')) {
          debugPrint(
            '🔑 [CREATE_USER] ⚠️ ATENÇÃO: Tokens encontrados na resposta de criação!',
          );
          debugPrint(
            '🔑 [CREATE_USER] Access Token: ${json['access_token']?.substring(0, 20) ?? 'N/A'}...',
          );
          debugPrint(
            '🔑 [CREATE_USER] Refresh Token: ${json['refresh_token']?.substring(0, 20) ?? 'N/A'}...',
          );
        } else {
          debugPrint(
            '🔑 [CREATE_USER] Nenhum token na resposta de criação (esperado fazer login depois)',
          );
        }

        final userResponse = UserPersonalDataResponse.fromJson(json);

        debugPrint('✅ Usuário criado - UID: ${userResponse.uid}');
        return userResponse;
      } else {
        debugPrint('❌ Create user failed: ${response.statusCode}');
        if (response.headers.containsKey('location')) {
          debugPrint('➡️ Location header: ${response.headers['location']}');
        }
        debugPrint('❌ Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Create user error: $e');
      return null;
    }
  }

  // PUT /users/{uid} → Atualiza usuário
  Future<UserPersonalDataResponse?> updateUser(
    String uid,
    UserPersonalData user,
  ) async {
    try {
      final token = _authManager.token;
      if (token == null) {
        debugPrint('❌ Nenhum token disponível para updateUser');
        return null;
      }

      final response = await _apiClient.authenticatedPut(
        'users/$uid',
        user.toJson(),
        token,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return UserPersonalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ Update user failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Update user error: $e');
      return null;
    }
  }

  // DELETE /users/{uid} → Remove usuário
  Future<bool> deleteUser(String uid) async {
    try {
      final token = _authManager.token;
      if (token == null) {
        debugPrint('❌ Nenhum token disponível para deleteUser');
        return false;
      }

      final response = await _apiClient.authenticatedDelete(
        'users/$uid',
        token,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ User deleted successfully');
        return true;
      } else {
        debugPrint(
          '❌ Delete user failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Delete user error: $e');
      return false;
    }
  }
}
