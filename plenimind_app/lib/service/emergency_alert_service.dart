import 'package:flutter/material.dart';
import 'package:plenimind_app/components/status/notifications/emergency_alert_dialog.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/service/feedback_service.dart';
import 'package:plenimind_app/service/call_service.dart';
import 'package:plenimind_app/schemas/dto/feedback_dto.dart';

class EmergencyAlertService {
  final FeedbackService _feedbackService = FeedbackService();
  final CallService _callService = CallService();
  bool _isShowingAlert = false;

  Future<void> showEmergencyAlert({
    required BuildContext context,
    required String uid,
    required UserVitalData vitalData,
    required String token,
  }) async {
    if (_isShowingAlert) return;

    _isShowingAlert = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => EmergencyAlertDialog(
            uid: uid,
            vitalData: vitalData,
            token: token,
            onConfirm: () async {
              _isShowingAlert = false;
              Navigator.of(context).pop();
              await _handleEmergencyConfirmed(uid, vitalData, token);
            },
            onFalseAlarm: () async {
              _isShowingAlert = false;
              Navigator.of(context).pop();
              await _handleFalseAlarm(uid, vitalData, token);
            },
          ),
    );
  }

  Future<void> _handleEmergencyConfirmed(
    String uid,
    UserVitalData vitalData,
    String token,
  ) async {
    try {
      debugPrint('✅ Usuário confirmou emergência - Iniciando chamadas');

      // Iniciar chamadas de emergência
      await _callService.startEmergencyCall(uid);

      // Enviar feedback positivo para IA
      await _feedbackService.sendFeedback(
        FeedbackDTO(
          uid: uid,
          features: {
            'heart_rate': vitalData.heartRate,
            'respiration_rate': vitalData.respirationRate,
            'accel_std': vitalData.accelStd,
            'spo2': vitalData.spo2,
            'stress_level': vitalData.stressLevel,
          },
          userFeedback: 1,
        ),
        token,
      );

      debugPrint('📊 Feedback positivo enviado para IA');
    } catch (e) {
      debugPrint('❌ Erro ao processar confirmação de emergência: $e');
    }
  }

  Future<void> _handleFalseAlarm(
    String uid,
    UserVitalData vitalData,
    String token,
  ) async {
    try {
      debugPrint('❌ Usuário reportou falso alarme');

      // Enviar feedback negativo para IA
      await _feedbackService.sendFeedback(
        FeedbackDTO(
          uid: uid,
          features: {
            'heart_rate': vitalData.heartRate,
            'respiration_rate': vitalData.respirationRate,
            'accel_std': vitalData.accelStd,
            'spo2': vitalData.spo2,
            'stress_level': vitalData.stressLevel,
          },
          userFeedback: 0,
        ),
        token,
      );

      debugPrint('📊 Feedback negativo enviado para IA');
    } catch (e) {
      debugPrint('❌ Erro ao processar falso alarme: $e');
    }
  }

  void dispose() {
    _isShowingAlert = false;
  }
}
