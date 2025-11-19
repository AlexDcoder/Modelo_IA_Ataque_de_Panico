import 'package:flutter/material.dart';
import 'package:plenimind_app/components/status/notifications/emergency_alert_dialog.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/service/feedback_service.dart';
import 'package:plenimind_app/service/call_service.dart';
import 'package:plenimind_app/schemas/dto/feedback_dto.dart';
import 'package:plenimind_app/service/contact_service.dart';

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
    if (_isShowingAlert) {
      debugPrint('⚠️ [EMERGENCY_ALERT_SERVICE] Alerta já está sendo exibido');
      return;
    }

    _isShowingAlert = true;
    debugPrint(
      '🚨 [EMERGENCY_ALERT_SERVICE] Exibindo alerta de emergência para: $uid',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => EmergencyAlertDialog(
            uid: uid,
            vitalData: vitalData,
            token: token,
            onConfirm: () async {
              debugPrint(
                '✅ [EMERGENCY_ALERT_SERVICE] Usuário confirmou emergência',
              );
              _isShowingAlert = false;
              Navigator.of(context).pop();
              await _handleEmergencyConfirmed(uid, vitalData, token, context);
            },
            onFalseAlarm: () async {
              debugPrint(
                '❌ [EMERGENCY_ALERT_SERVICE] Usuário relatou falso alarme',
              );
              _isShowingAlert = false;
              Navigator.of(context).pop();
              await _handleFalseAlarm(uid, vitalData, token, context);
            },
          ),
    );
  }

  Future<void> _handleEmergencyConfirmed(
    String uid,
    UserVitalData vitalData,
    String token,
    BuildContext context,
  ) async {
    try {
      debugPrint(
        '🔄 [EMERGENCY_ALERT_SERVICE] Processando confirmação de emergência...',
      );

      // ✅ VERIFICAÇÃO EXPANDIDA DE PERMISSÕES
      final hasPermission = await _callService.hasPhonePermission();
      if (!hasPermission) {
        debugPrint(
          '❌ [EMERGENCY_ALERT_SERVICE] Permissões de telefone insuficientes',
        );
        if (context.mounted) {
          await _showPermissionError(context);
        }
        return;
      }

      final contacts = await ContactService.getEmergencyContacts(uid);
      debugPrint(
        '📞 [EMERGENCY_ALERT_SERVICE] ${contacts.length} contatos de emergência encontrados',
      );

      if (contacts.isEmpty) {
        debugPrint('❌ [EMERGENCY_ALERT_SERVICE] NENHUM CONTATO CONFIGURADO!');
        if (context.mounted) {
          await _showNoContactsAlert(context, uid);
        }
        return;
      }

      // ✅ VALIDAR E FORMATAR TODOS OS NÚMEROS ANTES DE INICIAR
      debugPrint(
        '🔄 [EMERGENCY_ALERT_SERVICE] Validando números de contatos...',
      );
      final List<EmergencyContact> validContacts = [];

      for (final contact in contacts) {
        try {
          final formattedPhone = ContactService.validateAndFormatPhoneNumber(
            contact.phone,
          );
          final validContact = EmergencyContact(
            id: contact.id,
            name: contact.name,
            phone: formattedPhone,
            imageUrl: contact.imageUrl,
            priority: contact.priority,
          );
          validContacts.add(validContact);
          debugPrint('   ✅ ${contact.name}: $formattedPhone');
        } catch (e) {
          debugPrint('   ❌ ${contact.name}: Número inválido - ${e.toString()}');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Número inválido para ${contact.name}: ${contact.phone}',
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          // Não retornar imediatamente, apenas pular este contato
          continue;
        }
      }

      if (validContacts.isEmpty) {
        debugPrint('❌ [EMERGENCY_ALERT_SERVICE] NENHUM CONTATO VÁLIDO!');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Nenhum contato com número válido encontrado'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // ✅ SALVAR CONTATOS VALIDADOS LOCALMENTE
      await ContactService.saveEmergencyContacts(validContacts, uid);
      debugPrint(
        '✅ [EMERGENCY_ALERT_SERVICE] Contatos válidos salvos: ${validContacts.length}',
      );

      debugPrint(
        '📞 [EMERGENCY_ALERT_SERVICE] Iniciando chamadas de emergência para ${validContacts.length} contatos válidos...',
      );

      // ✅ INICIAR CHAMADAS APENAS COM CONTATOS VÁLIDOS
      await _callService.startEmergencyCall(uid);

      debugPrint(
        '📝 [EMERGENCY_ALERT_SERVICE] Enviando feedback de confirmação...',
      );
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

      if (context.mounted) {
        debugPrint(
          '✅ [EMERGENCY_ALERT_SERVICE] Emergência processada com sucesso',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Chamadas de emergência iniciadas para seus contatos',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '❌ [EMERGENCY_ALERT_SERVICE] Erro ao processar confirmação de emergência: $e',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao iniciar chamadas: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showPermissionError(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Permissões Insuficientes'),
            ],
          ),
          content: const Text(
            'Permissões de telefone são necessárias para fazer chamadas de emergência. '
            'Por favor, conceda as permissões necessárias nas configurações do aplicativo.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToSettings(context);
              },
              child: const Text('Configurações'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNoContactsAlert(BuildContext context, String userId) async {
    debugPrint(
      '⚠️ [EMERGENCY_ALERT_SERVICE] Exibindo alerta de contatos ausentes',
    );
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Contatos Não Configurados'),
            ],
          ),
          content: const Text(
            'Você não tem contatos de emergência configurados. '
            'Para sua segurança, configure pelo menos um contato de emergência '
            'nas configurações do aplicativo.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint(
                  'ℹ️ [EMERGENCY_ALERT_SERVICE] Usuário entendeu alerta de contatos',
                );
                Navigator.of(context).pop();
              },
              child: const Text('Entendi'),
            ),
            TextButton(
              onPressed: () {
                debugPrint(
                  '⚙️ [EMERGENCY_ALERT_SERVICE] Usuário navegando para configurações',
                );
                Navigator.of(context).pop();
                _navigateToSettings(context);
              },
              child: const Text('Configurar Agora'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSettings(BuildContext context) {
    debugPrint('🧭 [EMERGENCY_ALERT_SERVICE] Navegando para configurações');
    Navigator.pushNamed(context, '/settings');
  }

  Future<void> _handleFalseAlarm(
    String uid,
    UserVitalData vitalData,
    String token,
    BuildContext context,
  ) async {
    try {
      debugPrint('🔄 [EMERGENCY_ALERT_SERVICE] Processando falso alarme...');

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

      if (context.mounted) {
        debugPrint(
          '✅ [EMERGENCY_ALERT_SERVICE] Falso alarme registrado com sucesso',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Falso alarme registrado'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '❌ [EMERGENCY_ALERT_SERVICE] Erro ao processar falso alarme: $e',
      );
    }
  }

  void dispose() {
    debugPrint('🔄 [EMERGENCY_ALERT_SERVICE] Dispose chamado');
    _isShowingAlert = false;
  }
}
