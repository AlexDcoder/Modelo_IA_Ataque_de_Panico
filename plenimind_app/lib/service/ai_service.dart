import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';

import 'api_client.dart';

class AIService {
  final ApiClient _apiClient = ApiClient();

  // POST /ai/predict → Predição de ataque de pânico
  Future<Map<String, dynamic>?> predictPanicAttack(
    UserVitalData vitals,
    String token,
  ) async {
    try {
      final response = await _apiClient.authenticatedPost(
        'ai/predict',
        vitals.toJson(),
        token,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
          '❌ AI prediction failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ AI prediction error: $e');
      return null;
    }
  }
}
