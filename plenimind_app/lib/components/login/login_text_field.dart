import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool passwordVisible;
  final ValueChanged<bool>? onPasswordVisibilityChanged;
  final double screenWidth;

  const LoginTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    this.keyboardType,
    this.isPassword = false,
    this.passwordVisible = false,
    this.onPasswordVisibilityChanged,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: isPassword && !passwordVisible,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.inter(
          color: Colors.grey[600],
          fontSize: screenWidth * 0.04,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(40),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.all(screenWidth * 0.04),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[600],
                    size: screenWidth * 0.05,
                  ),
                  onPressed: () {
                    onPasswordVisibilityChanged?.call(!passwordVisible);
                  },
                )
                : null,
      ),
      style: GoogleFonts.inter(fontSize: screenWidth * 0.04),
    );
  }
}
