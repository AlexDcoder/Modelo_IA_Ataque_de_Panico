import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileNextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double screenWidth;

  const ProfileNextButton({
    super.key,
    required this.onPressed,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.05),
      child: SizedBox(
        width: screenWidth * 0.7,
        height: screenWidth * 0.13,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Próximo',
            style: GoogleFonts.interTight(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
