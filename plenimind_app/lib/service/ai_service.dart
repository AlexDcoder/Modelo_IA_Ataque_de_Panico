import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/service/api_client.dart';

class AIService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>?> predictPanicAttack(
    UserVitalData vitals,
    String token,
  ) async {
    try {
      debugPrint('🧠 [AI_SERVICE] Enviando dados para predição de IA...');
      debugPrint('   📊 Dados vitais enviados:');
      debugPrint('   - Heart Rate: ${vitals.heartRate}');
      debugPrint('   - Respiration Rate: ${vitals.respirationRate}');
      debugPrint('   - Accel Std: ${vitals.accelStd}');
      debugPrint('   - SPO2: ${vitals.spo2}');
      debugPrint('   - Stress Level: ${vitals.stressLevel}');

      final response = await _apiClient.authenticatedPost(
        'ai/predict',
        vitals.toJson(),
        token,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [AI_SERVICE] Predição recebida com sucesso');
        final result = jsonDecode(response.body);
        debugPrint('   🎯 Resultado: $result');
        return result;
      } else {
        debugPrint(
          '❌ [AI_SERVICE] AI prediction failed: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [AI_SERVICE] AI prediction error: $e');
      return null;
    }
  }
}
