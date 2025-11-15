import 'dart:convert';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/core/auth/auth_service.dart';
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
        print('❌ Nenhum token disponível para getAllUsers');
        return null;
      }

      final response = await _apiClient.authenticatedGet('users', token);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(
          '❌ Get all users failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Get all users error: $e');
      return null;
    }
  }

  // ✅ NOVO: GET /users/me → Dados do usuário atual
  Future<UserPersonalDataResponse?> getCurrentUser() async {
    try {
      print('👤 Buscando usuário atual...');

      final token = _authManager.token;
      if (token == null) {
        print('❌ getCurrentUser: Token NULO no AuthManager');
        return null;
      }

      print(
        '✅ getCurrentUser: Token disponível (${token.substring(0, 20)}...)',
      );

      final response = await _apiClient.authenticatedGet('users/me', token);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final userResponse = UserPersonalDataResponse.fromJson(json);

        print('✅ Rota /me funcionou - UserId: ${userResponse.uid}');
        return userResponse;
      } else {
        print(
          '❌ getCurrentUser failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ getCurrentUser error: $e');
      return null;
    }
  }

  // GET /users/{uid} → Dados públicos de usuário
  Future<UserPersonalDataResponse?> getUserPublic(String uid) async {
    try {
      final token = _authManager.token;
      if (token == null) {
        print('❌ Nenhum token disponível para getUserPublic');
        return null;
      }

      final response = await _apiClient.authenticatedGet('users/$uid', token);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return UserPersonalDataResponse.fromJson(json);
      } else {
        print(
          '❌ Get user public failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Get user public error: $e');
      return null;
    }
  }

  // POST /users/ → Cria novo usuário
  Future<UserPersonalDataResponse?> createUser(UserPersonalData user) async {
    try {
      print('👤 Criando usuário: ${user.email}');

      final response = await _apiClient.post('users', user.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final userResponse = UserPersonalDataResponse.fromJson(json);

        print('✅ Usuário criado - UID: ${userResponse.uid}');
        return userResponse;
      } else {
        print('❌ Create user failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Create user error: $e');
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
        print('❌ Nenhum token disponível para updateUser');
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
        print('❌ Update user failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Update user error: $e');
      return null;
    }
  }

  // DELETE /users/{uid} → Remove usuário
  Future<bool> deleteUser(String uid) async {
    try {
      final token = _authManager.token;
      if (token == null) {
        print('❌ Nenhum token disponível para deleteUser');
        return false;
      }

      final response = await _apiClient.authenticatedDelete(
        'users/$uid',
        token,
      );

      if (response.statusCode == 200) {
        print('✅ User deleted successfully');
        return true;
      } else {
        print('❌ Delete user failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Delete user error: $e');
      return false;
    }
  }
}
