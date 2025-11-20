import 'package:flutter/material.dart';
import 'package:plenimind_app/components/login/login_button.dart';
import 'package:plenimind_app/components/login/login_form_header.dart';
import 'package:plenimind_app/components/login/login_text_field.dart';

class SignInTab extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool passwordVisible;
  final ValueChanged<bool> onPasswordVisibilityChanged;
  final bool isLoading;
  final VoidCallback onSubmit;
  final double screenWidth;

  const SignInTab({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.passwordVisible,
    required this.onPasswordVisibilityChanged,
    required this.isLoading,
    required this.onSubmit,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.05,
        screenWidth * 0.03,
        screenWidth * 0.05,
        0,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoginFormHeader(
              title: 'Bem-vindo de Volta',
              subtitle:
                  'Preencha as informações abaixo para acessar sua conta.',
              screenWidth: screenWidth,
            ),
            SizedBox(height: screenWidth * 0.05),
            LoginTextField(
              controller: emailController,
              focusNode: emailFocusNode,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              screenWidth: screenWidth,
              isEmail: true,
            ),
            SizedBox(height: screenWidth * 0.04),
            LoginTextField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              labelText: 'Senha',
              isPassword: true,
              passwordVisible: passwordVisible,
              onPasswordVisibilityChanged: onPasswordVisibilityChanged,
              screenWidth: screenWidth,
            ),
            SizedBox(height: screenWidth * 0.05),
            LoginButton(
              text: 'Entrar',
              isLoading: isLoading,
              onPressed: onSubmit,
              screenWidth: screenWidth,
            ),
            SizedBox(height: screenWidth * 0.04),
            SizedBox(height: screenWidth * 0.04),
          ],
        ),
      ),
    );
  }
}
