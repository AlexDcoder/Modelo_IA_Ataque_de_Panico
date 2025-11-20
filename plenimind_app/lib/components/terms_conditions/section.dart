import 'package:flutter/material.dart';

class TermsSection extends StatelessWidget {
  final String title;
  final String content;
  final double screenWidth;

  const TermsSection({
    super.key,
    required this.title,
    required this.content,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            height: 1.3,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        Text(
          content,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: colorScheme.surface.withValues(alpha: 0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}
