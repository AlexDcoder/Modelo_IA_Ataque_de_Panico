import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginHeader extends StatelessWidget {
  final double screenWidth;

  const LoginHeader({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.05,
        screenWidth * 0.03,
        screenWidth * 0.05,
        screenWidth * 0.05,
      ),
      child: Container(
        width: double.infinity,
        height: screenWidth * 0.3,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.only(bottom: screenWidth * 0.1),
          child: Text(
            'PleniMind',
            style: GoogleFonts.interTight(
              fontSize: screenWidth * 0.08,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
