import 'package:flutter/material.dart';
import 'package:plenimind_app/components/terms_conditions/acceptance.dart';
import 'package:plenimind_app/components/terms_conditions/content.dart';
import 'package:plenimind_app/components/terms_conditions/continue_button.dart';
import 'package:plenimind_app/components/terms_conditions/custom_app_bar.dart';
import 'package:plenimind_app/components/terms_conditions/header.dart';
import 'package:plenimind_app/core/auth/permission_manager.dart';

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

  Future<void> _onContinuePressed() async {
    // ✅ CORREÇÃO: Salvar que o usuário aceitou os termos
    if (_isAccepted) {
      await PermissionManager.setTermsAccepted(true);
      debugPrint('✅ Termos de uso aceitos e salvos');
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            TermsHeader(),
            const SizedBox(height: 24),
            Expanded(child: TermsContent()),
            const SizedBox(height: 24),
            TermsAcceptance(
              isAccepted: _isAccepted,
              onChanged: _onAcceptanceChanged,
            ),
            const SizedBox(height: 16),
            ContinueButton(
              isEnabled: _isAccepted,
              onPressed: _onContinuePressed,
            ),
            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }
}
