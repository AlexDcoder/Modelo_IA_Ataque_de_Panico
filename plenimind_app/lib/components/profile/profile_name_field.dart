import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileNameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double screenWidth;

  const ProfileNameField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenWidth * 0.02,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Seu Nome',
          labelStyle: GoogleFonts.inter(
            color: Theme.of(context).textTheme.labelMedium?.color,
            fontSize: screenWidth * 0.04,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          contentPadding: EdgeInsets.all(screenWidth * 0.04),
        ),
        style: GoogleFonts.inter(fontSize: screenWidth * 0.04),
      ),
    );
  }
}
