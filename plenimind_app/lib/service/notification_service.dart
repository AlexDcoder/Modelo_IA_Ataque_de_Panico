import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  static const String _panicDetectionChannel = 'panic_detection_channel';
  static const String _normalStatusChannel = 'normal_status_channel';

  // Inicializar notificações
  Future<void> initialize() async {
    try {
      await AwesomeNotifications().initialize(null, [
        NotificationChannel(
          channelKey: _panicDetectionChannel,
          channelName: 'Emergency Alerts',
          channelDescription:
              'Emergency notifications for panic attack detection',
          importance: NotificationImportance.High,
          defaultColor: Colors.red,
          ledColor: Colors.red,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          criticalAlerts: true,
        ),
        NotificationChannel(
          channelKey: _normalStatusChannel,
          channelName: 'Health Status',
          channelDescription: 'Normal health status notifications',
          importance: NotificationImportance.Default,
          defaultColor: Colors.green,
        ),
      ]);

      // Configurar ações para notificações interativas
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onActionReceivedMethod,
      );

      // Request permissions
      bool isAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();

      if (isAllowed) {
        await PermissionManager.setNotificationPermissionGranted(true);
      }

      debugPrint('Notification system initialized: $isAllowed');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // ✅ CORREÇÃO: Processar dados vitais SEMPRE, independente do feedback
  Future<void> processVitalDataAndNotify(
    String uid,
    UserVitalData vitalData,
    String token,
  ) async {
    try {
      // ✅ SEMPRE enviar dados para IA para análise
      final prediction = await _aiService.predictPanicAttack(vitalData, token);
      final panicDetected = prediction?['panic_attack_detected'] ?? false;
      final confidence = prediction?['confidence'] ?? 0.0;

      debugPrint(
        '🧠 IA analisou dados - Ataque: $panicDetected, Confiança: ${(confidence * 100).toStringAsFixed(1)}%',
      );

      if (panicDetected && confidence > 0.7) {
        // ✅ Mostrar notificação interativa de emergência
        await _showInteractivePanicNotification(
          uid,
          vitalData,
          token,
          confidence,
        );

        debugPrint(
          '🚨 Notificação de emergência enviada - Aguardando resposta do usuário',
        );
      } else {
        // ✅ CORREÇÃO: Mesmo em casos normais, mostrar notificação informativa
        // mas NÃO enviar feedback automático para IA
        await _showNormalStatusNotification(uid, vitalData, token);

        debugPrint('✅ Status normal - Dados processados, sem feedback para IA');
      }
    } catch (e) {
      debugPrint('❌ Error processing vital data: $e');
      await _showErrorNotification();
    }
  }

  Future<void> _showInteractivePanicNotification(
    String uid,
    UserVitalData vitalData,
    String token,
    double confidence,
  ) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _generateNotificationId(),
          channelKey: _panicDetectionChannel,
          title: '🚨 Possível Ataque de Pânico Detectado',
          body:
              'Confiança: ${(confidence * 100).toStringAsFixed(1)}%.\n'
              'Confirmar emergência para acionar contatos?',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Call,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          autoDismissible: false,
          payload: {
            'uid': uid,
            'heart_rate': vitalData.heartRate.toString(),
            'respiration_rate': vitalData.respirationRate.toString(),
            'accel_std': vitalData.accelStd.toString(),
            'spo2': vitalData.spo2.toString(),
            'stress_level': vitalData.stressLevel.toString(),
            'token': token,
          },
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'confirm_emergency',
            label: '✅ Sim, Emergência Real',
          ),
          NotificationActionButton(key: 'false_alarm', label: '❌ Falso Alarme'),
        ],
      );

      debugPrint('📱 Notificação interativa de emergência enviada');
    } catch (e) {
      debugPrint('Error showing interactive panic notification: $e');
      // Fallback: notificação não interativa
      await _showPanicAttackNotification(uid, vitalData, token);
    }
  }

  static Future<void> _onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint(
      '📱 Ação de notificação recebida: ${receivedAction.buttonKeyPressed}',
    );

    final payload = receivedAction.payload ?? {};
    final uid = payload['uid']?.toString();
    final token = payload['token']?.toString();

    if (uid == null || token == null) {
      debugPrint('❌ Dados insuficientes na notificação');
      return;
    }

    try {
      final vitalData = UserVitalData(
        heartRate: double.parse(payload['heart_rate'] ?? '0'),
        respirationRate: double.parse(payload['respiration_rate'] ?? '0'),
        accelStd: double.parse(payload['accel_std'] ?? '0'),
        spo2: double.parse(payload['spo2'] ?? '0'),
        stressLevel: double.parse(payload['stress_level'] ?? '0'),
      );

      final notificationService = NotificationService();
      final callService = CallService();
      final feedbackService = FeedbackService();

      if (receivedAction.buttonKeyPressed == 'confirm_emergency') {
        debugPrint('✅ Usuário confirmou emergência - Acionando contatos');

        // Iniciar chamadas de emergência
        await callService.startEmergencyCall(uid);

        // ✅ Enviar feedback positivo APENAS quando usuário confirma
        await feedbackService.sendFeedback(
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
      } else if (receivedAction.buttonKeyPressed == 'false_alarm') {
        debugPrint('❌ Usuário reportou falso alarme - Atualizando modelo');

        // ✅ Enviar feedback negativo APENAS quando usuário reporta falso alarme
        await feedbackService.sendFeedback(
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

        // Mostrar confirmação de falso alarme
        await notificationService._showFalseAlarmConfirmation();
      }
    } catch (e) {
      debugPrint('❌ Erro ao processar ação da notificação: $e');
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
          id: _generateNotificationId(),
          channelKey: _panicDetectionChannel,
          title: '🚨 Possível Ataque de Pânico Detectado',
          body:
              'Seus dados vitais indicam um possível ataque. Iniciando chamadas de emergência...',
          notificationLayout: NotificationLayout.BigText,
        ),
      );

      // Iniciar chamadas de emergência automaticamente (fallback)
      await _callService.startEmergencyCall(uid);

      debugPrint('⚠️ Modo fallback - Chamadas iniciadas sem feedback');
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
          id: _generateNotificationId(),
          channelKey: _normalStatusChannel,
          title: '✅ Status de Saúde Normal',
          body: 'Seus dados vitais estão dentro dos parâmetros normais.',
          notificationLayout: NotificationLayout.Default,
        ),
      );

      debugPrint('💚 Notificação de status normal enviada');
    } catch (e) {
      debugPrint('Error showing normal notification: $e');
    }
  }

  Future<void> _showFalseAlarmConfirmation() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _generateNotificationId(),
          channelKey: _normalStatusChannel,
          title: '✅ Falso Alarme Registrado',
          body:
              'Obrigado pelo feedback! Isso ajuda a melhorar a precisão do sistema.',
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      debugPrint('Error showing false alarm confirmation: $e');
    }
  }

  Future<void> _showErrorNotification() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _generateNotificationId(),
          channelKey: _normalStatusChannel,
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

  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  Future<void> clearAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
