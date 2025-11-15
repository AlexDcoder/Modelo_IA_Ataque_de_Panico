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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoginFormHeader(
              title: 'Bem-vindo de Volta',
              subtitle:
                  'Preencha as informações abaixo para acessar sua conta.',
            ),
            const SizedBox(height: 24),
            LoginTextField(
              controller: emailController,
              focusNode: emailFocusNode,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            LoginTextField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              labelText: 'Senha',
              isPassword: true,
              passwordVisible: passwordVisible,
              onPasswordVisibilityChanged: onPasswordVisibilityChanged,
            ),
            const SizedBox(height: 24),
            LoginButton(
              text: 'Entrar',
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
