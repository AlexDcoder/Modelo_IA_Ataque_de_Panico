import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_phone_call_state/flutter_phone_call_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';
import 'package:plenimind_app/service/contact_service.dart';

class CallService {
  final _phoneCallStatePlugin = PhoneCallState.instance;

  StreamSubscription? _subscription;
  bool _callAnswered = false;
  bool _isCalling = false;
  Completer<void>? _currentCallCompleter;

  /// Solicita permissões e inicia o monitor de chamadas
  Future<void> requestPermission() async {
    try {
      final results =
          await [Permission.notification, Permission.phone].request();

      final notificationGranted =
          results[Permission.notification]?.isGranted ?? false;
      final phoneGranted = results[Permission.phone]?.isGranted ?? false;

      if (notificationGranted && phoneGranted && Platform.isAndroid) {
        // ✅ CORREÇÃO: Não usar await se retorna void, apenas chamar o método
        PhoneCallState.instance.startMonitorService();
        debugPrint("✅ Monitor de chamadas iniciado");
        return;
      } else {
        throw Exception("Permissões de telefone/notificação negadas");
      }
    } catch (e) {
      debugPrint("❌ Erro ao solicitar permissões: $e");
      throw Exception("Erro ao configurar serviço de chamadas: $e");
    }
  }

  /// Inicia o fluxo de chamadas de emergência
  Future<void> startEmergencyCall(String userId) async {
    if (_isCalling) {
      debugPrint("⚠️ Chamada de emergência já em andamento");
      return;
    }

    _isCalling = true;
    _callAnswered = false;
    _currentCallCompleter = Completer<void>();

    try {
      debugPrint("🔄 Iniciando chamadas de emergência para usuário: $userId");

      // Solicitar permissões se necessário
      await requestPermission();

      final List<EmergencyContact> contacts =
          await ContactService.getEmergencyContacts(userId);

      if (contacts.isEmpty) {
        throw Exception("Nenhum contato de emergência configurado");
      }

      // Ordenar contatos por prioridade
      final sortedContacts = ContactService.sortByPriority(contacts);
      debugPrint(
        "📞 ${sortedContacts.length} contatos ordenados por prioridade",
      );

      // Inicia o listener do estado da chamada
      _subscribeToPhoneState();

      // Realizar chamadas em sequência até alguém atender
      for (final contact in sortedContacts) {
        if (_callAnswered) {
          debugPrint('✅ Chamada atendida por ${contact.name}');
          break;
        }

        debugPrint(
          '📞 Ligando para ${contact.name} (${contact.phone}) - Prioridade: ${contact.priority}',
        );

        final callSuccess = await _makeCall(contact.phone);

        if (callSuccess) {
          await _waitForCallCompletion();
        }

        if (!_callAnswered) {
          debugPrint('❌ ${contact.name} não atendeu, tentando próximo...');
        }
      }

      if (!_callAnswered) {
        debugPrint('⚠️ Nenhum contato atendeu a chamada de emergência');
      }

      debugPrint('✅ Processo de chamadas de emergência finalizado');
      _currentCallCompleter?.complete();
    } catch (e) {
      debugPrint('❌ Erro durante chamadas de emergência: $e');
      _currentCallCompleter?.completeError(e);
      throw Exception("Erro ao realizar chamadas de emergência: $e");
    } finally {
      _cleanup();
    }
  }

  /// ✅ CORREÇÃO: Método _makeCall corrigido para tratar bool? corretamente
  Future<bool> _makeCall(String phoneNumber) async {
    try {
      final bool? result = await FlutterPhoneDirectCaller.callNumber(
        phoneNumber,
      );

      // ✅ CORREÇÃO: Tratamento adequado do bool?
      if (result == null) {
        debugPrint("⚠️ Resultado da chamada é nulo para: $phoneNumber");
        return false;
      }

      if (!result) {
        debugPrint("❌ Falha ao iniciar chamada para: $phoneNumber");
        return false;
      }

      debugPrint("✅ Chamada iniciada com sucesso para: $phoneNumber");
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao fazer chamada para $phoneNumber: $e");
      return false;
    }
  }

  /// Escuta as mudanças no estado da chamada
  void _subscribeToPhoneState() {
    _subscription?.cancel();
    _subscription = _phoneCallStatePlugin.phoneStateChange.listen((event) {
      debugPrint("📞 Estado da chamada: ${event.state.description}");

      switch (event.state) {
        case CallState.call:
        case CallState.outgoingAccept:
        case CallState.incoming:
        case CallState.hold:
          if (!_callAnswered) {
            _callAnswered = true;
            debugPrint('✅ Chamada atendida!');
          }
          break;
        case CallState.end:
        case CallState.none:
          _isCalling = false;
          debugPrint('📞 Chamada finalizada');
          break;
        default:
          break;
      }
    });
  }

  /// Espera até que a chamada termine
  Future<void> _waitForCallCompletion() async {
    final completer = Completer<void>();
    late StreamSubscription tempSub;

    tempSub = _phoneCallStatePlugin.phoneStateChange.listen((event) {
      if (event.state == CallState.end || event.state == CallState.none) {
        tempSub.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // Timeout de 45 segundos para chamada não atendida
    try {
      await completer.future.timeout(const Duration(seconds: 45));
    } on TimeoutException {
      debugPrint("⏰ Timeout - chamada não atendida após 45 segundos");
      tempSub.cancel();
      // Não completamos o completer aqui porque estamos tratando timeout
    }
  }

  /// Para as chamadas de emergência
  Future<void> stopEmergencyCalls() async {
    debugPrint("🛑 Parando chamadas de emergência");
    _callAnswered = true;
    _cleanup();
    _currentCallCompleter?.complete();
  }

  /// Verifica se está realizando chamadas
  bool get isCalling => _isCalling;

  /// Verifica se alguma chamada foi atendida
  bool get callAnswered => _callAnswered;

  /// Limpa os recursos
  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    _isCalling = false;
    _callAnswered = false;
  }

  /// Dispose para liberar recursos
  void dispose() {
    _cleanup();
    _currentCallCompleter?.complete();
  }
}
