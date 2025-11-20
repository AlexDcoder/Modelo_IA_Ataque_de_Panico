import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/schemas/response/user_vital_data.dart';
import 'package:plenimind_app/service/api_client.dart';

class VitalDataService {
  final ApiClient _apiClient = ApiClient();

  Future<UserVitalDataResponse?> createOrUpdateVitalData(
    String uid,
    UserVitalData vitals,
    String token,
  ) async {
    try {
      debugPrint(
        '🔄 [VITAL_DATA_SERVICE] Criando/atualizando dados vitais para: $uid',
      );
      debugPrint('   ❤️  Dados vitais:');
      debugPrint('   - Heart Rate: ${vitals.heartRate}');
      debugPrint('   - Respiration Rate: ${vitals.respirationRate}');
      debugPrint('   - Accel Std: ${vitals.accelStd}');
      debugPrint('   - SPO2: ${vitals.spo2}');
      debugPrint('   - Stress Level: ${vitals.stressLevel}');

      final response = await _apiClient.authenticatedPost(
        'vital-data/$uid',
        vitals.toJson(),
        token,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [VITAL_DATA_SERVICE] Dados vitais salvos com sucesso');
        final json = jsonDecode(response.body);
        return UserVitalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ [VITAL_DATA_SERVICE] Create/update vital data failed: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [VITAL_DATA_SERVICE] Create/update vital data error: $e');
      return null;
    }
  }

  Future<UserVitalDataResponse?> getUserVitalData(
    String uid,
    String token,
  ) async {
    try {
      debugPrint('🔄 [VITAL_DATA_SERVICE] Buscando dados vitais para: $uid');

      final response = await _apiClient.authenticatedGet(
        'vital-data/$uid',
        token,
      );

      if (response.statusCode == 200) {
        debugPrint(
          '✅ [VITAL_DATA_SERVICE] Dados vitais carregados com sucesso',
        );
        final json = jsonDecode(response.body);
        return UserVitalDataResponse.fromJson(json);
      } else if (response.statusCode == 404) {
        debugPrint(
          'ℹ️ [VITAL_DATA_SERVICE] Nenhum dado vital encontrado para: $uid (primeiro acesso)',
        );
        return null;
      } else {
        debugPrint(
          '❌ [VITAL_DATA_SERVICE] Get user vital data failed: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [VITAL_DATA_SERVICE] Get user vital data error: $e');
      return null;
    }
  }

  Future<UserVitalDataResponse?> updateVitalData(
    String uid,
    UserVitalData vitals,
    String token,
  ) async {
    try {
      debugPrint('🔄 [VITAL_DATA_SERVICE] Atualizando dados vitais para: $uid');
      debugPrint('   📊 Novos dados:');
      debugPrint(
        '   - HR: ${vitals.heartRate} | RR: ${vitals.respirationRate}',
      );
      debugPrint('   - SPO2: ${vitals.spo2} | Stress: ${vitals.stressLevel}');

      final response = await _apiClient.authenticatedPut(
        'vital-data/$uid',
        vitals.toJson(),
        token,
      );

      if (response.statusCode == 200) {
        debugPrint(
          '✅ [VITAL_DATA_SERVICE] Dados vitais atualizados com sucesso',
        );
        final json = jsonDecode(response.body);
        return UserVitalDataResponse.fromJson(json);
      } else {
        debugPrint(
          '❌ [VITAL_DATA_SERVICE] Update vital data failed: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [VITAL_DATA_SERVICE] Update vital data error: $e');
      return null;
    }
  }

  Future<bool> deleteVitalData(String uid, String token) async {
    try {
      debugPrint('🔄 [VITAL_DATA_SERVICE] Deletando dados vitais para: $uid');

      final response = await _apiClient.authenticatedDelete(
        'vital-data/$uid',
        token,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [VITAL_DATA_SERVICE] Vital data deleted successfully');
        return true;
      } else {
        debugPrint(
          '❌ [VITAL_DATA_SERVICE] Delete vital data failed: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [VITAL_DATA_SERVICE] Delete vital data error: $e');
      return false;
    }
  }
}
