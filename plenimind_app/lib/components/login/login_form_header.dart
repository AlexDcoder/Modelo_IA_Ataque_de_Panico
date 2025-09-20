import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const LoginFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.interTight(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
