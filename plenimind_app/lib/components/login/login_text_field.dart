import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plenimind_app/utils/email_validator.dart';

class LoginTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool passwordVisible;
  final ValueChanged<bool>? onPasswordVisibilityChanged;
  final double screenWidth;
  final bool isEmail;

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
    this.isEmail = false,
  });

  @override
  State<LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<LoginTextField> {
  late bool _isEmailValid;

  @override
  void initState() {
    super.initState();
    _isEmailValid =
        widget.isEmail ? EmailValidator.isValid(widget.controller.text) : true;
    widget.controller.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onEmailChanged);
    super.dispose();
  }

  void _onEmailChanged() {
    if (widget.isEmail) {
      setState(() {
        _isEmailValid = EmailValidator.isValid(widget.controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorText =
        widget.isEmail && !_isEmailValid
            ? EmailValidator.getErrorMessage(widget.controller.text)
            : null;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword && !widget.passwordVisible,
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: GoogleFonts.inter(
          color: Colors.grey[600],
          fontSize: widget.screenWidth * 0.04,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color:
                widget.isEmail && !_isEmailValid
                    ? Theme.of(context).colorScheme.error
                    : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color:
                widget.isEmail && !_isEmailValid
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
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.all(widget.screenWidth * 0.04),
        errorText: errorText,
        suffixIcon:
            widget.isPassword
                ? IconButton(
                  icon: Icon(
                    widget.passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                    size: widget.screenWidth * 0.05,
                  ),
                  onPressed: () {
                    widget.onPasswordVisibilityChanged?.call(
                      !widget.passwordVisible,
                    );
                  },
                )
                : widget.isEmail
                ? Icon(
                  _isEmailValid ? Icons.check_circle : Icons.error,
                  color: _isEmailValid ? Colors.green : Colors.red,
                  size: widget.screenWidth * 0.05,
                )
                : null,
      ),
      style: GoogleFonts.inter(fontSize: widget.screenWidth * 0.04),
    );
  }
}
