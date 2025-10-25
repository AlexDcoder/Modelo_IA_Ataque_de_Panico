import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_phone_call_state/flutter_phone_call_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plenimind_app/service/contact_service.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';

class CallService {
  final _phoneCallStatePlugin = PhoneCallState.instance;

  StreamSubscription? _subscription;
  bool _callAnswered = false;
  bool _isCalling = false;

  /// Solicita permissões e inicia o monitor de chamadas
  Future<void> requestPermission() async {
    final results = await [
      Permission.notification,
      Permission.phone,
    ].request();

    if (results[Permission.notification]?.isGranted == true &&
        results[Permission.phone]?.isGranted == true &&
        Platform.isAndroid) {
      PhoneCallState.instance.startMonitorService();
      debugPrint("Monitor de chamadas iniciado.");
    } else {
      throw Exception("Permissões de telefone/notification negadas.");
    }
  }

  /// Inicia o fluxo de chamadas de emergência
  Future<void> startEmergencyCall(String userId) async {
    if (_isCalling) return;

    _isCalling = true;
    _callAnswered = false;

    final List<EmergencyContact> contacts =
        await ContactService.getEmergencyContacts(userId);

    contacts.sort((a, b) => a.priority.compareTo(b.priority));

    // Inicia o listener do estado da chamada
    _subscribeToPhoneState();

    for (final contact in contacts) {
      if (_callAnswered) break; // alguém já atendeu → parar
      debugPrint('Ligando para ${contact.name} (${contact.phone})');

      await FlutterPhoneDirectCaller.callNumber(contact.phone);
      await _waitForCallToEnd();

      if (!_callAnswered) {
        debugPrint('${contact.name} não atendeu, tentando o próximo...');
      }
    }

    debugPrint('Processo de chamadas encerrado.');
    _cleanup();
  }

  /// Escuta as mudanças no estado da chamada
  void _subscribeToPhoneState() {
    _subscription?.cancel();
    _subscription = _phoneCallStatePlugin.phoneStateChange.listen((event) {
      debugPrint("Estado da chamada: ${event.state.description}");

      switch (event.state) {
        case CallState.call:
        case CallState.outgoingAccept:
        case CallState.incoming:
        case CallState.hold:
          _callAnswered = true; // alguém atendeu
          debugPrint('Ligação atendida!');
          break;
        case CallState.end:
        case CallState.none:
          _isCalling = false;
          break;
        default:
          break;
      }
    });
  }

  /// Espera até que a chamada termine
  Future<void> _waitForCallToEnd() async {
    final completer = Completer<void>();
    late StreamSubscription tempSub;

    tempSub = _phoneCallStatePlugin.phoneStateChange.listen((event) {
      if (event.state == CallState.end || event.state == CallState.none) {
        tempSub.cancel();
        completer.complete();
      }
    });
    await completer.future;
  }

  /// Limpa o listener
  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    _isCalling = false;
  }
}
