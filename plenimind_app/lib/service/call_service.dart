import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_phone_call_state/flutter_phone_call_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';
import 'package:plenimind_app/service/contact_service.dart';
import 'package:plenimind_app/core/auth/permission_manager.dart';

class CallService {
  final _phoneCallStatePlugin = PhoneCallState.instance;

  StreamSubscription? _subscription;
  bool _callAnswered = false;
  bool _isCalling = false;
  Completer<void>? _currentCallCompleter;

  Future<bool> hasPhonePermission() async {
    try {
      final termsPermission =
          await PermissionManager.getPhonePermissionGranted();
      final systemPermission = await Permission.phone.status;
      return termsPermission && systemPermission.isGranted;
    } catch (e) {
      debugPrint('❌ [CALL_SERVICE] Erro ao verificar permissões: $e');
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      debugPrint('🔄 [CALL_SERVICE] Verificando permissões de telefone...');

      final phonePermission =
          await PermissionManager.getPhonePermissionGranted();
      if (!phonePermission) {
        throw Exception("Permissão de telefone não concedida nos termos");
      }

      var status = await Permission.phone.status;
      if (!status.isGranted) {
        debugPrint(
          '📞 [CALL_SERVICE] Solicitando permissão de telefone do sistema...',
        );
        status = await Permission.phone.request();

        if (!status.isGranted) {
          throw Exception("Permissão de telefone negada pelo usuário");
        }

        await PermissionManager.setPhonePermissionGranted(true);
      }

      if (Platform.isAndroid) {
        debugPrint(
          '🤖 [CALL_SERVICE] Iniciando monitoramento de chamadas no Android',
        );
        PhoneCallState.instance.startMonitorService();
      }

      debugPrint(
        '✅ [CALL_SERVICE] Permissões de telefone validadas com sucesso',
      );
    } catch (e) {
      debugPrint('❌ [CALL_SERVICE] Erro nas permissões de telefone: $e');
      throw Exception("Permissões de telefone insuficientes: $e");
    }
  }

  Future<void> startEmergencyCall(String userId) async {
    if (_isCalling) {
      debugPrint('⚠️ [CALL_SERVICE] Chamada de emergência já em andamento');
      return;
    }

    _isCalling = true;
    _callAnswered = false;
    _currentCallCompleter = Completer<void>();

    try {
      debugPrint(
        '🚨 [CALL_SERVICE] INICIANDO CHAMADAS DE EMERGÊNCIA para usuário: $userId',
      );

      await requestPermission();

      final List<EmergencyContact> contacts =
          await ContactService.getEmergencyContacts(userId);
      debugPrint(
        '📞 [CALL_SERVICE] ${contacts.length} contatos de emergência carregados',
      );

      if (contacts.isEmpty) {
        debugPrint('❌ [CALL_SERVICE] NENHUM CONTATO CONFIGURADO - ABORTANDO');
        throw Exception("Nenhum contato de emergência configurado");
      }

      final sortedContacts = ContactService.sortByPriority(contacts);
      debugPrint('📞 [CALL_SERVICE] Contatos ordenados por prioridade:');
      for (var contact in sortedContacts) {
        debugPrint(
          '   ${contact.priority}. ${contact.name} - ${contact.phone}',
        );
      }

      _subscribeToPhoneState();

      debugPrint(
        '📞 [CALL_SERVICE] Iniciando sequência de chamadas para ${sortedContacts.length} contatos',
      );

      for (final contact in sortedContacts) {
        if (_callAnswered) {
          debugPrint(
            '✅ [CALL_SERVICE] Chamada atendida por ${contact.name} - PARANDO SEQUÊNCIA',
          );
          break;
        }

        debugPrint(
          '📞 [CALL_SERVICE] Ligando para ${contact.name} (${contact.phone}) - Prioridade: ${contact.priority}',
        );

        final callSuccess = await _makeCall(contact.phone);

        if (callSuccess) {
          await _waitForCallCompletion();
        }

        if (!_callAnswered) {
          debugPrint(
            '❌ [CALL_SERVICE] ${contact.name} não atendeu, tentando próximo...',
          );
        }
      }

      if (!_callAnswered) {
        debugPrint(
          '⚠️ [CALL_SERVICE] NENHUM CONTATO ATENDEU A CHAMADA DE EMERGÊNCIA',
        );
      } else {
        debugPrint('✅ [CALL_SERVICE] Emergência atendida com sucesso');
      }

      _currentCallCompleter?.complete();
    } catch (e) {
      debugPrint('❌ [CALL_SERVICE] Erro durante chamadas de emergência: $e');
      _currentCallCompleter?.completeError(e);
      throw Exception("Erro ao realizar chamadas de emergência: $e");
    } finally {
      _cleanup();
    }
  }

  Future<bool> _makeCall(String phoneNumber) async {
    try {
      debugPrint('📞 [CALL_SERVICE] Discando para: $phoneNumber');

      final bool? result = await FlutterPhoneDirectCaller.callNumber(
        phoneNumber,
      );

      if (result == true) {
        debugPrint(
          '✅ [CALL_SERVICE] Chamada iniciada com sucesso para: $phoneNumber',
        );
        return true;
      } else {
        debugPrint(
          '❌ [CALL_SERVICE] Falha ao iniciar chamada para: $phoneNumber',
        );
        return false;
      }
    } catch (e) {
      debugPrint(
        '❌ [CALL_SERVICE] Erro ao fazer chamada para $phoneNumber: $e',
      );
      return false;
    }
  }

  void _subscribeToPhoneState() {
    debugPrint(
      '📞 [CALL_SERVICE] Inscrito no monitoramento de estado de chamada',
    );

    _subscription?.cancel();
    _subscription = _phoneCallStatePlugin.phoneStateChange.listen((event) {
      debugPrint(
        "📞 [CALL_SERVICE] Estado da chamada: ${event.state.description}",
      );

      switch (event.state) {
        case CallState.call:
        case CallState.outgoingAccept:
        case CallState.incoming:
        case CallState.hold:
          if (!_callAnswered) {
            _callAnswered = true;
            debugPrint('✅ [CALL_SERVICE] CHAMADA ATENDIDA!');
          }
          break;
        case CallState.end:
        case CallState.none:
          _isCalling = false;
          debugPrint('📞 [CALL_SERVICE] Chamada finalizada');
          break;
        default:
          break;
      }
    });
  }

  Future<void> _waitForCallCompletion() async {
    debugPrint('⏳ [CALL_SERVICE] Aguardando conclusão da chamada...');
    final completer = Completer<void>();
    late StreamSubscription tempSub;

    tempSub = _phoneCallStatePlugin.phoneStateChange.listen((event) {
      if (event.state == CallState.end || event.state == CallState.none) {
        debugPrint('📞 [CALL_SERVICE] Chamada finalizada no monitoramento');
        tempSub.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    try {
      await completer.future.timeout(const Duration(seconds: 45));
      debugPrint('✅ [CALL_SERVICE] Chamada concluída dentro do timeout');
    } on TimeoutException {
      debugPrint(
        "⏰ [CALL_SERVICE] TIMEOUT - chamada não atendida após 45 segundos",
      );
      tempSub.cancel();
    }
  }

  Future<void> stopEmergencyCalls() async {
    debugPrint('🛑 [CALL_SERVICE] Parando chamadas de emergência');
    _callAnswered = true;
    _cleanup();
    _currentCallCompleter?.complete();
  }

  bool get isCalling => _isCalling;
  bool get callAnswered => _callAnswered;

  void _cleanup() {
    debugPrint('🧹 [CALL_SERVICE] Limpando recursos de chamada');
    _subscription?.cancel();
    _subscription = null;
    _isCalling = false;
    _callAnswered = false;
  }

  void dispose() {
    debugPrint('♻️ [CALL_SERVICE] Dispose chamado');
    _cleanup();
    _currentCallCompleter?.complete();
  }
}
