import 'package:flutter/foundation.dart';
import 'package:plenimind_app/schemas/dto/feedback_dto.dart';
import 'package:plenimind_app/service/api_client.dart';

class FeedbackService {
  final ApiClient _apiClient = ApiClient();

  Future<bool> sendFeedback(FeedbackDTO feedback, String token) async {
    try {
      debugPrint('🔄 [FEEDBACK_SERVICE] Enviando feedback para IA...');
      debugPrint('   👤 UID: ${feedback.uid}');
      debugPrint('   📊 Features: ${feedback.features.length}');
      debugPrint('   👍 Feedback: ${feedback.userFeedback}');

      // Validar dados antes do envio
      if (feedback.uid.isEmpty) {
        debugPrint('❌ [FEEDBACK_SERVICE] UID vazio - feedback inválido');
        return false;
      }

      if (feedback.features.isEmpty) {
        debugPrint('❌ [FEEDBACK_SERVICE] Features vazias - feedback inválido');
        return false;
      }

      final response = await _apiClient.authenticatedPost(
        'feedback',
        feedback.toJson(),
        token,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '✅ [FEEDBACK_SERVICE] Feedback enviado com sucesso para treinamento da IA',
        );
        return true;
      } else {
        debugPrint(
          '❌ [FEEDBACK_SERVICE] Send feedback failed: ${response.statusCode}',
        );

        // Tratamento específico para erros comuns
        if (response.statusCode == 403) {
          debugPrint(
            '🔐 [FEEDBACK_SERVICE] 403 Forbidden - Token pode estar expirado',
          );
        } else if (response.statusCode == 400) {
          debugPrint(
            '📝 [FEEDBACK_SERVICE] 400 Bad Request - Dados do feedback inválidos',
          );
        }

        return false;
      }
    } catch (e) {
      debugPrint('❌ [FEEDBACK_SERVICE] Send feedback error: $e');
      return false;
    }
  }
}
