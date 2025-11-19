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

  Future<UserPersonalDataResponse?> updateUserProfile({
    required String uid,
    required String username,
    required String email,
  }) async {
    try {
      debugPrint('🔄 [USER_SERVICE] Atualizando perfil para: $uid');
      debugPrint('   📝 Novos dados - Username: $username, Email: $email');

      final token = _authManager.token;
      if (token == null) {
        debugPrint('❌ [USER_SERVICE] Token não disponível para updateProfile');
        return null;
      }

      final response = await _apiClient.authenticatedPut('users/$uid', {
        'username': username,
        'email': email,
      }, token);

      if (response.statusCode == 200) {
        debugPrint('✅ [USER_SERVICE] Perfil atualizado com sucesso');
        final json = jsonDecode(response.body);
        return UserPersonalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ [USER_SERVICE] Update profile failed: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Update profile error: $e');
      return null;
    }
  }

  Future<UserPersonalDataResponse?> updateUserDetectionTime({
    required String uid,
    required String detectionTime,
  }) async {
    try {
      debugPrint('🔄 [USER_SERVICE] Atualizando detectionTime para: $uid');
      debugPrint('   ⏰ Novo tempo: $detectionTime');

      final token = _authManager.token;
      if (token == null) {
        debugPrint(
          '❌ [USER_SERVICE] Token não disponível para updateDetectionTime',
        );
        return null;
      }

      final response = await _apiClient.authenticatedPut('users/$uid', {
        'detection_time': detectionTime,
      }, token);

      if (response.statusCode == 200) {
        debugPrint('✅ [USER_SERVICE] DetectionTime atualizado com sucesso');
        final json = jsonDecode(response.body);
        return UserPersonalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ [USER_SERVICE] Update detectionTime failed: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Update detectionTime error: $e');
      return null;
    }
  }

  // ✅ MÉTODO ATUALIZADO PARA ALTERAÇÃO DE SENHA COM VALIDAÇÃO
  Future<UserPersonalDataResponse?> updateUserPassword({
    required String uid,
    required String newPassword,
    String? currentPassword, // PARÂMETRO OPCIONAL PARA VALIDAÇÃO
  }) async {
    try {
      debugPrint('🔄 [USER_SERVICE] Atualizando senha para: $uid');

      final token = _authManager.token;
      if (token == null) {
        debugPrint('❌ [USER_SERVICE] Token não disponível para updatePassword');
        return null;
      }

      // PREPARAR DADOS PARA ENVIO
      final Map<String, dynamic> updateData = {'password': newPassword};

      // SE FOR FORNECIDA SENHA ATUAL, ADICIONAR À REQUISIÇÃO
      if (currentPassword != null && currentPassword.isNotEmpty) {
        updateData['current_password'] = currentPassword;
        debugPrint('   🔐 Validação com senha atual habilitada');
      }

      final response = await _apiClient.authenticatedPut(
        'users/$uid',
        updateData,
        token,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [USER_SERVICE] Senha atualizada com sucesso');
        final json = jsonDecode(response.body);
        return UserPersonalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ [USER_SERVICE] Update password failed: ${response.statusCode}',
        );

        // LOG ESPECÍFICO PARA ERROS COMUNS
        if (response.statusCode == 400) {
          debugPrint(
            '   📝 Possível erro: Senha atual incorreta ou nova senha inválida',
          );
        } else if (response.statusCode == 401) {
          debugPrint('   🔐 Token expirado ou inválido');
        }

        return null;
      }
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Update password error: $e');
      return null;
    }
  }

  Future<UserPersonalDataResponse?> updateUserEmergencyContacts({
    required String uid,
    required List<EmergencyContactDTO> emergencyContacts,
  }) async {
    try {
      debugPrint('🔄 [USER_SERVICE] Atualizando contatos para: $uid');
      debugPrint('   📞 Número de contatos: ${emergencyContacts.length}');

      final token = _authManager.token;
      if (token == null) {
        debugPrint(
          '❌ [USER_SERVICE] Token não disponível para updateEmergencyContacts',
        );
        return null;
      }

      final response = await _apiClient.authenticatedPut('users/$uid', {
        'emergency_contact': emergencyContacts.map((e) => e.toJson()).toList(),
      }, token);

      if (response.statusCode == 200) {
        debugPrint('✅ [USER_SERVICE] Contatos atualizados com sucesso');
        final json = jsonDecode(response.body);
        return UserPersonalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ [USER_SERVICE] Update emergencyContacts failed: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Update emergencyContacts error: $e');
      return null;
    }
  }

  Future<UserPersonalDataResponse?> updateUserMultipleFields({
    required String uid,
    String? username,
    String? email,
    String? password,
    String? detectionTime,
    List<EmergencyContactDTO>? emergencyContacts,
  }) async {
    try {
      debugPrint('🔄 [USER_SERVICE] Atualizando múltiplos campos para: $uid');

      final token = _authManager.token;
      if (token == null) {
        debugPrint(
          '❌ [USER_SERVICE] Token não disponível para update múltiplo',
        );
        return null;
      }

      final updateData = <String, dynamic>{};

      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (password != null) updateData['password'] = password;
      if (detectionTime != null) updateData['detection_time'] = detectionTime;
      if (emergencyContacts != null) {
        updateData['emergency_contact'] =
            emergencyContacts.map((e) => e.toJson()).toList();
      }

      debugPrint(
        '📝 [USER_SERVICE] Campos para atualização: ${updateData.keys}',
      );

      final response = await _apiClient.authenticatedPut(
        'users/$uid',
        updateData,
        token,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [USER_SERVICE] Múltiplos campos atualizados com sucesso');
        final json = jsonDecode(response.body);
        return UserPersonalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ [USER_SERVICE] Update múltiplo failed: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Update múltiplo error: $e');
      return null;
    }
  }

  Future<UserPersonalDataResponse?> getCurrentUser() async {
    try {
      debugPrint('🔄 [USER_SERVICE] Buscando usuário atual...');

      final token = _authManager.token;
      if (token == null) {
        debugPrint(
          '❌ [USER_SERVICE] Token NULO - usuário possivelmente não autenticado',
        );
        return null;
      }

      debugPrint('✅ [USER_SERVICE] Token disponível, buscando dados...');

      final response = await _apiClient.authenticatedGet('users/me', token);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final userResponse = UserPersonalDataResponse.fromJson(json);

        debugPrint('✅ [USER_SERVICE] Dados do usuário carregados com sucesso');
        debugPrint('   👤 UID: ${userResponse.uid}');
        debugPrint('   📧 Email: ${userResponse.email}');
        debugPrint('   ⏰ Detecção: ${userResponse.detectionTime}');
        debugPrint('   📞 Contatos: ${userResponse.emergencyContacts.length}');

        return userResponse;
      } else if (response.statusCode == 401) {
        debugPrint('🔐 [USER_SERVICE] Token inválido ou expirado');
        await _authManager.clearTokens();
        return null;
      } else {
        debugPrint(
          '❌ [USER_SERVICE] getCurrentUser failed: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] getCurrentUser error: $e');
      return null;
    }
  }

  Future<UserPersonalDataResponse?> createUser(UserPersonalData user) async {
    try {
      debugPrint('🔄 [USER_SERVICE] Criando usuário: ${user.email}');

      final response = await _apiClient.post('users', user.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);

        debugPrint(
          '✅ [USER_SERVICE] Usuário criado - Status: ${response.statusCode}',
        );
        debugPrint('✅ [USER_SERVICE] Response Body: ${response.body}');

        final userResponse = UserPersonalDataResponse.fromJson(json);
        debugPrint('✅ [USER_SERVICE] UID criado: ${userResponse.uid}');
        return userResponse;
      } else {
        debugPrint(
          '❌ [USER_SERVICE] Create user failed: ${response.statusCode}',
        );
        debugPrint('❌ [USER_SERVICE] Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Create user error: $e');
      return null;
    }
  }

  Future<bool> deleteUser(String uid) async {
    try {
      debugPrint('🔄 [USER_SERVICE] Deletando usuário: $uid');

      final token = _authManager.token;
      if (token == null) {
        debugPrint('❌ [USER_SERVICE] Token não disponível para deleteUser');
        return false;
      }

      final response = await _apiClient.authenticatedDelete(
        'users/$uid',
        token,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [USER_SERVICE] User deleted successfully');
        return true;
      } else {
        debugPrint(
          '❌ [USER_SERVICE] Delete user failed: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Delete user error: $e');
      return false;
    }
  }
}
