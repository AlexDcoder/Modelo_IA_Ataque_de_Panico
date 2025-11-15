import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileTitle extends StatelessWidget {
  const ProfileTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Criar seu Perfil',
      style: GoogleFonts.interTight(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.headlineMedium?.color,
      ),
    );
  }
}
