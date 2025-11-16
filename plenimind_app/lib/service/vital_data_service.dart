import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/schemas/response/user_vital_data.dart';
import 'package:plenimind_app/service/api_client.dart';

class VitalDataService {
  final ApiClient _apiClient = ApiClient();

  // ✅ CORREÇÃO: Usar a rota correta POST /vital-data/{uid}
  Future<UserVitalDataResponse?> createOrUpdateVitalData(
    String uid,
    UserVitalData vitals,
    String token,
  ) async {
    try {
      // ✅ CORREÇÃO: A rota correta é vital-data/{uid}, não vital-data/
      final response = await _apiClient.authenticatedPost(
        'vital-data/$uid', // ✅ Rota correta
        vitals.toJson(),
        token,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return UserVitalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ Create/update vital data failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Create/update vital data error: $e');
      return null;
    }
  }

  // GET /vital-data/{uid} → Dados vitais do usuário
  Future<UserVitalDataResponse?> getUserVitalData(
    String uid,
    String token,
  ) async {
    try {
      final response = await _apiClient.authenticatedGet(
        'vital-data/$uid',
        token,
      );

      // ✅ CORREÇÃO: Tratar 404 como cenário normal (primeiro acesso)
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return UserVitalDataResponse.fromJson(json);
      } else if (response.statusCode == 404) {
        // ✅ CORREÇÃO: 404 não é erro - é cenário normal para novo usuário
        debugPrint(
          'ℹ️ No vital data found for user: $uid (first access or no data yet)',
        );
        return null;
      } else {
        debugPrint(
          '❌ Get user vital data failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Get user vital data error: $e');
      return null;
    }
  }

  // PUT /vital-data/{uid} → Atualiza dados vitais
  Future<UserVitalDataResponse?> updateVitalData(
    String uid,
    UserVitalData vitals,
    String token,
  ) async {
    try {
      final response = await _apiClient.authenticatedPut(
        'vital-data/$uid',
        vitals.toJson(),
        token,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return UserVitalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ Update vital data failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Update vital data error: $e');
      return null;
    }
  }

  // DELETE /vital-data/{uid} → Remove dados vitais
  Future<bool> deleteVitalData(String uid, String token) async {
    try {
      final response = await _apiClient.authenticatedDelete(
        'vital-data/$uid',
        token,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Vital data deleted successfully');
        return true;
      } else {
        debugPrint(
          '❌ Delete vital data failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Delete vital data error: $e');
      return false;
    }
  }
}
