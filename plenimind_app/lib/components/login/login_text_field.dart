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
  final String? errorText;
  final bool showError;

  const LoginTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    this.keyboardType,
    this.isPassword = false,
    this.passwordVisible = false,
    this.onPasswordVisibilityChanged,
    this.errorText,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: isPassword && !passwordVisible,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:
                    showError
                        ? Theme.of(context).colorScheme.error
                        : Colors.grey[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:
                    showError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
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
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(24),
            suffixIcon:
                isPassword
                    ? IconButton(
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        onPasswordVisibilityChanged?.call(!passwordVisible);
                      },
                    )
                    : null,
          ),
          style: GoogleFonts.inter(),
        ),
        if (showError && errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              errorText!,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
