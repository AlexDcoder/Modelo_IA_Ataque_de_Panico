import 'package:flutter/material.dart';
import 'package:plenimind_app/components/login/animated_login_card.dart';
import 'package:plenimind_app/components/login/login_header.dart';
import 'package:plenimind_app/pages/profile.dart';
import 'package:plenimind_app/pages/status_page.dart';
import 'package:plenimind_app/core/auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static String routePath = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _emailCreateController = TextEditingController();
  final TextEditingController _passwordCreateController =
      TextEditingController();
  final FocusNode _emailCreateFocusNode = FocusNode();
  final FocusNode _passwordCreateFocusNode = FocusNode();
  bool _passwordCreateVisible = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _passwordVisible = false;

  bool _isSignUpLoading = false;
  bool _isSignInLoading = false;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCreateController.dispose();
    _passwordCreateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailCreateFocusNode.dispose();
    _passwordCreateFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_emailCreateController.text.isEmpty ||
        _passwordCreateController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isSignUpLoading = true);

    try {
      // TODO: Integrar com Firebase Auth ou API real
      await Future.delayed(const Duration(seconds: 1));

      _showSnackBar('Account created successfully!');

      // FLUXO 1: Sign Up -> ProfilePage
      Navigator.pushReplacementNamed(context, ProfilePage.routePath);
    } catch (e) {
      _showSnackBar('Sign up failed: ${e.toString()}');
    } finally {
      setState(() => _isSignUpLoading = false);
    }
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isSignInLoading = true);

    try {
      final success = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (success) {
        _showSnackBar('Signed in successfully!');
        Navigator.pushReplacementNamed(context, StatusPage.routePath);
      }
    } catch (e) {
      _showSnackBar('Sign in failed: ${e.toString()}');
    } finally {
      setState(() => _isSignInLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            const LoginHeader(),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 170),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedLoginCard(
                        tabController: _tabController,
                        // Create Account Props
                        emailCreateController: _emailCreateController,
                        passwordCreateController: _passwordCreateController,
                        emailCreateFocusNode: _emailCreateFocusNode,
                        passwordCreateFocusNode: _passwordCreateFocusNode,
                        passwordCreateVisible: _passwordCreateVisible,
                        onPasswordCreateVisibilityChanged: (visible) {
                          setState(() => _passwordCreateVisible = visible);
                        },
                        isSignUpLoading: _isSignUpLoading,
                        onSignUp: _handleSignUp,
                        // Sign In Props
                        emailController: _emailController,
                        passwordController: _passwordController,
                        emailFocusNode: _emailFocusNode,
                        passwordFocusNode: _passwordFocusNode,
                        passwordVisible: _passwordVisible,
                        onPasswordVisibilityChanged: (visible) {
                          setState(() => _passwordVisible = visible);
                        },
                        isSignInLoading: _isSignInLoading,
                        onSignIn: _handleSignIn,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
