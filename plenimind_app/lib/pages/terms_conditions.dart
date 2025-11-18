import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plenimind_app/components/terms_conditions/acceptance.dart';
import 'package:plenimind_app/components/terms_conditions/content.dart';
import 'package:plenimind_app/components/terms_conditions/continue_button.dart';
import 'package:plenimind_app/components/terms_conditions/custom_app_bar.dart';
import 'package:plenimind_app/components/terms_conditions/header.dart';
import 'package:plenimind_app/core/auth/permission_manager.dart';
import 'dart:io';

class TermsConditionsScreen extends StatefulWidget {
  static const String routePath = '/terms-conditions';

  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  bool _isAccepted = false;

  void _onAcceptanceChanged(bool value) {
    setState(() {
      _isAccepted = value;
    });
  }

  Future<void> _requestAllPermissions() async {
    try {
      debugPrint('🔐 Solicitando todas as permissões necessárias...');

      // 1. Permissão de Contatos
      final contactsStatus = await Permission.contacts.request();
      await PermissionManager.setContactsPermissionGranted(
        contactsStatus.isGranted,
      );
      debugPrint(
        '📱 Permissão de contatos: ${contactsStatus.isGranted ? "✅" : "❌"}',
      );

      // 2. Permissão de Telefone (Android)
      if (Platform.isAndroid) {
        final phoneStatus = await Permission.phone.request();
        await PermissionManager.setPhonePermissionGranted(
          phoneStatus.isGranted,
        );
        debugPrint(
          '📞 Permissão de telefone: ${phoneStatus.isGranted ? "✅" : "❌"}',
        );
      }

      // 3. Permissão de Notificações
      final notificationAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
      await PermissionManager.setNotificationPermissionGranted(
        notificationAllowed,
      );
      debugPrint(
        '🔔 Permissão de notificações: ${notificationAllowed ? "✅" : "❌"}',
      );

      if (!contactsStatus.isGranted) {
        _showPermissionWarning('contatos');
      }
    } catch (e) {
      debugPrint('❌ Erro ao solicitar permissões: $e');
    }
  }

  void _showPermissionWarning(String permission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ Permissão de $permission é necessária para o funcionamento completo do app',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _onContinuePressed() async {
    if (_isAccepted) {
      // Solicitar todas as permissões
      await _requestAllPermissions();

      // Salvar aceitação dos termos
      await PermissionManager.setTermsAccepted(true);
      debugPrint('✅ Termos de uso aceitos e permissões solicitadas');

      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(screenWidth: screenWidth),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            TermsHeader(screenWidth: screenWidth),
            SizedBox(height: screenHeight * 0.03),
            Expanded(child: TermsContent(screenWidth: screenWidth)),
            SizedBox(height: screenHeight * 0.03),
            TermsAcceptance(
              isAccepted: _isAccepted,
              onChanged: _onAcceptanceChanged,
              screenWidth: screenWidth,
            ),
            SizedBox(height: screenHeight * 0.02),
            ContinueButton(
              isEnabled: _isAccepted,
              onPressed: _onContinuePressed,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
            ),
            SizedBox(height: screenHeight * 0.04),
          ],
        ),
      ),
    );
  }
}
