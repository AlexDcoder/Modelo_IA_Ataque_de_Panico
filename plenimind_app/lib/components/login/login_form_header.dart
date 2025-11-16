import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double screenWidth;

  const LoginFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.interTight(
            fontSize: screenWidth * 0.07,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: screenWidth * 0.035,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
