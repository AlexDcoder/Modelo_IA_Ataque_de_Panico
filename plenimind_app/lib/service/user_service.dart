import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/schemas/dto/emergency_contact_dto.dart';
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

  // ✅ CORREÇÃO: GET /users/me → Dados do usuário atual
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

        debugPrint('📤 [CREATE_USER] Response Status: ${response.statusCode}');
        debugPrint('📤 [CREATE_USER] Response Body Completo: ${response.body}');

        final userResponse = UserPersonalDataResponse.fromJson(json);

        debugPrint('✅ Usuário criado - UID: ${userResponse.uid}');
        return userResponse;
      } else {
        debugPrint('❌ Create user failed: ${response.statusCode}');
        debugPrint('❌ Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Create user error: $e');
      return null;
    }
  }

  // ✅ CORREÇÃO: PUT /users/{uid} → Atualiza usuário (completo)
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

  // ✅ NOVO: Atualização parcial usando PUT com dados existentes
  Future<UserPersonalDataResponse?> updateUserPartial(
    String uid,
    Map<String, dynamic> partialData,
  ) async {
    try {
      final token = _authManager.token;
      if (token == null) {
        debugPrint('❌ Nenhum token disponível para updateUserPartial');
        return null;
      }

      // Primeiro buscar dados atuais do usuário
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        debugPrint('❌ Não foi possível obter dados atuais do usuário');
        return null;
      }

      // Converter currentUser para UserPersonalData (mantendo dados existentes)
      final currentUserData = UserPersonalData(
        username: currentUser.username,
        email: currentUser.email,
        password: '', // Senha não é retornada, manter vazia
        detectionTime: currentUser.detectionTime,
        emergencyContacts: currentUser.emergencyContacts,
      );

      // Mesclar dados atuais com dados parciais
      final mergedData = _mergeUserData(currentUserData, partialData);

      // Fazer PUT com dados completos
      final response = await _apiClient.authenticatedPut(
        'users/$uid',
        mergedData.toJson(),
        token,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return UserPersonalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ Update user partial failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Update user partial error: $e');
      return null;
    }
  }

  // ✅ NOVO: Métodos específicos para atualizações parciais
  Future<UserPersonalDataResponse?> updateUserPassword(
    String uid,
    String newPassword,
  ) async {
    return await updateUserPartial(uid, {'password': newPassword});
  }

  Future<UserPersonalDataResponse?> updateUserProfile(
    String uid,
    String username,
    String email,
  ) async {
    return await updateUserPartial(uid, {'username': username, 'email': email});
  }

  Future<UserPersonalDataResponse?> updateUserDetectionTime(
    String uid,
    String detectionTime,
  ) async {
    return await updateUserPartial(uid, {'detection_time': detectionTime});
  }

  Future<UserPersonalDataResponse?> updateUserEmergencyContacts(
    String uid,
    List<EmergencyContactDTO> emergencyContacts,
  ) async {
    return await updateUserPartial(uid, {
      'emergency_contact': emergencyContacts.map((e) => e.toJson()).toList(),
    });
  }

  // ✅ NOVO: Método para mesclar dados do usuário
  UserPersonalData _mergeUserData(
    UserPersonalData currentData,
    Map<String, dynamic> partialData,
  ) {
    return UserPersonalData(
      username: partialData['username'] ?? currentData.username,
      email: partialData['email'] ?? currentData.email,
      password: partialData['password'] ?? currentData.password,
      detectionTime: partialData['detection_time'] ?? currentData.detectionTime,
      emergencyContacts:
          partialData['emergency_contact'] != null
              ? (partialData['emergency_contact'] as List)
                  .map((e) => EmergencyContactDTO.fromJson(e))
                  .toList()
              : currentData.emergencyContacts,
    );
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
