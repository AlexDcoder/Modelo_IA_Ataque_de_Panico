import 'package:flutter/material.dart';

class TermsHeader extends StatelessWidget {
  final double screenWidth;

  const TermsHeader({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Termos de Uso e\nCompromissos',
          style: TextStyle(
            fontSize: screenWidth * 0.07,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        SizedBox(height: screenWidth * 0.04),
        Text(
          'Para utilizar o PleniMind, você precisa concordar com os seguintes termos e autorizar o acesso às funcionalidades necessárias para o funcionamento adequado do aplicativo.',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
