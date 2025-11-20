import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/service/ai_service.dart';
import 'package:plenimind_app/service/emergency_alert_service.dart';
import 'package:plenimind_app/core/auth/permission_manager.dart';

class NotificationService {
  final AIService _aiService = AIService();
  final EmergencyAlertService _emergencyAlertService = EmergencyAlertService();

  static const String _panicDetectionChannel = 'panic_detection_channel';
  static const String _normalStatusChannel = 'normal_status_channel';

  NotificationService();

  Future<void> initialize() async {
    try {
      debugPrint(
        '🔄 [NOTIFICATION_SERVICE] Inicializando serviço de notificações...',
      );

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

      final notificationPermission =
          await PermissionManager.getNotificationPermissionGranted();

      if (!notificationPermission) {
        debugPrint(
          '🔔 [NOTIFICATION_SERVICE] Permissão de notificações não concedida nos termos',
        );
      } else {
        debugPrint(
          '✅ [NOTIFICATION_SERVICE] Permissão de notificações concedida',
        );
      }

      debugPrint('✅ [NOTIFICATION_SERVICE] Serviço inicializado com sucesso');
    } catch (e) {
      debugPrint(
        '❌ [NOTIFICATION_SERVICE] Error initializing notifications: $e',
      );
    }
  }

  Future<void> processVitalDataAndNotify(
    String uid,
    UserVitalData vitalData,
    String token,
    BuildContext context,
  ) async {
    try {
      debugPrint(
        '🧠 [NOTIFICATION_SERVICE] Processando dados vitais para IA...',
      );
      debugPrint(
        '   📊 Dados: HR=${vitalData.heartRate}, RR=${vitalData.respirationRate}, SPO2=${vitalData.spo2}',
      );

      final prediction = await _aiService.predictPanicAttack(vitalData, token);
      final panicDetected = prediction?['panic_attack_detected'] ?? false;

      debugPrint(
        '🧠 [NOTIFICATION_SERVICE] IA analisou dados - Ataque detectado: $panicDetected',
      );

      if (panicDetected) {
        debugPrint(
          '🚨 [NOTIFICATION_SERVICE] POSSÍVEL ATAQUE DE PÂNICO DETECTADO!',
        );
        await _emergencyAlertService.showEmergencyAlert(
          context: context,
          uid: uid,
          vitalData: vitalData,
          token: token,
        );
      } else {
        debugPrint(
          '✅ [NOTIFICATION_SERVICE] Status normal - Dados processados',
        );
      }
    } catch (e) {
      debugPrint('❌ [NOTIFICATION_SERVICE] Error processing vital data: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    debugPrint('🔄 [NOTIFICATION_SERVICE] Limpando todas as notificações...');
    await AwesomeNotifications().cancelAll();
    debugPrint('✅ [NOTIFICATION_SERVICE] Notificações limpas');
  }
}
