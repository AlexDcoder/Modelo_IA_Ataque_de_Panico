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
    if (_isAccepted) {
      await PermissionManager.setTermsAccepted(true);
      debugPrint('✅ Termos de uso aceitos e salvos');
    }
    Navigator.of(context).pop(true);
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
