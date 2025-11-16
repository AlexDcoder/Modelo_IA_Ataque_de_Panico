import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:plenimind_app/schemas/dto/feedback_dto.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/service/ai_service.dart';
import 'package:plenimind_app/service/call_service.dart';
import 'package:plenimind_app/service/feedback_service.dart';
import 'package:plenimind_app/core/auth/permission_manager.dart';

class NotificationService {
  final AIService _aiService = AIService();
  final FeedbackService _feedbackService = FeedbackService();
  final CallService _callService = CallService();

  // Inicializar notificações
  Future<void> initialize() async {
    try {
      // Initialize Awesome Notifications with default settings
      await AwesomeNotifications().initialize(null, [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for health alerts',
        ),
      ]);

      // Request permissions for notifications
      bool isAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();

      // ✅ CORREÇÃO: Salvar que a permissão de notificações foi concedida
      if (isAllowed) {
        await PermissionManager.setNotificationPermissionGranted(true);
      }

      debugPrint('Notification permission granted: $isAllowed');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Processar dados vitais: enviar para IA e mostrar notificação baseada no resultado
  Future<void> processVitalDataAndNotify(
    String uid,
    UserVitalData vitalData,
    String token,
  ) async {
    try {
      // Fazer predição com a IA
      final prediction = await _aiService.predictPanicAttack(vitalData, token);
      final panicDetected = prediction?['panic_attack_detected'] ?? false;

      if (panicDetected) {
        // Mostrar notificação de emergência
        await _showPanicAttackNotification(uid, vitalData, token);
      } else {
        // Mostrar notificação normal
        await _showNormalStatusNotification(uid, vitalData, token);
      }
    } catch (e) {
      debugPrint('❌ Error processing vital data: $e');
      await _showErrorNotification();
    }
  }

  Future<void> _showPanicAttackNotification(
    String uid,
    UserVitalData vitalData,
    String token,
  ) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'basic_channel',
          title: '🚨 Possível Ataque de Pânico Detectado',
          body:
              'Seus dados vitais indicam um possível ataque. Iniciando chamadas de emergência...',
          notificationLayout: NotificationLayout.BigText,
        ),
      );

      // Iniciar chamadas de emergência automaticamente
      await _callService.startEmergencyCall(uid);

      // Enviar feedback positivo (confirmando o ataque)
      await _sendFeedback(uid, vitalData, 1, token);
    } catch (e) {
      debugPrint('Error showing panic notification: $e');
    }
  }

  Future<void> _showNormalStatusNotification(
    String uid,
    UserVitalData vitalData,
    String token,
  ) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 2,
          channelKey: 'basic_channel',
          title: '✅ Status de Saúde Normal',
          body: 'Seus dados vitais estão dentro dos parâmetros normais.',
          notificationLayout: NotificationLayout.Default,
        ),
      );

      // Enviar feedback negativo (não foi ataque)
      await _sendFeedback(uid, vitalData, 0, token);
    } catch (e) {
      debugPrint('Error showing normal notification: $e');
    }
  }

  Future<void> _showErrorNotification() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 3,
          channelKey: 'basic_channel',
          title: '❌ Erro no Sistema',
          body:
              'Não foi possível processar seus dados vitais. Tente novamente.',
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      debugPrint('Error showing error notification: $e');
    }
  }

  Future<void> _sendFeedback(
    String uid,
    UserVitalData vitalData,
    int userFeedback,
    String token,
  ) async {
    final feedback = FeedbackDTO(
      uid: uid,
      features: {
        'heart_rate': vitalData.heartRate,
        'respiration_rate': vitalData.respirationRate,
        'accel_std': vitalData.accelStd,
        'spo2': vitalData.spo2,
        'stress_level': vitalData.stressLevel,
      },
      userFeedback: userFeedback,
    );

    await _feedbackService.sendFeedback(feedback, token);
  }
}
