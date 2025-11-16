import 'package:flutter/foundation.dart';
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

  // ✅ CORREÇÃO: Processar dados vitais e mostrar alerta quando detectado
  Future<void> processVitalDataAndNotify(
    String uid,
    UserVitalData vitalData,
    String token,
    BuildContext context,
  ) async {
    try {
      final prediction = await _aiService.predictPanicAttack(vitalData, token);
      final panicDetected = prediction?['panic_attack_detected'] ?? false;

      debugPrint('🧠 IA analisou dados - Ataque: $panicDetected');

      if (panicDetected) {
        // ✅ CORREÇÃO: Removida verificação de confidence > 0.7
        await _emergencyAlertService.showEmergencyAlert(
          context: context,
          uid: uid,
          vitalData: vitalData,
          token: token,
        );

        debugPrint('🚨 Alerta de emergência enviado para interface');
      } else {
        debugPrint('✅ Status normal - Dados processados');
      }
    } catch (e) {
      debugPrint('❌ Error processing vital data: $e');
    }
  }

  // Gerar ID único para notificações
  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  // Limpar notificações
  Future<void> clearAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
