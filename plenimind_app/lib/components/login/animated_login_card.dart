import 'package:flutter/material.dart';
import 'package:plenimind_app/components/login/create_acount_tab.dart';
import 'package:plenimind_app/components/login/login_tab_bar.dart';
import 'package:plenimind_app/components/login/sign_in_tab.dart';

class AnimatedLoginCard extends StatefulWidget {
  final TabController tabController;
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;

  // Create Account Props
  final TextEditingController emailCreateController;
  final TextEditingController passwordCreateController;
  final FocusNode emailCreateFocusNode;
  final FocusNode passwordCreateFocusNode;
  final bool passwordCreateVisible;
  final ValueChanged<bool> onPasswordCreateVisibilityChanged;
  final bool isSignUpLoading;
  final VoidCallback onSignUp;

  // Sign In Props
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool passwordVisible;
  final ValueChanged<bool> onPasswordVisibilityChanged;
  final bool isSignInLoading;
  final VoidCallback onSignIn;

  const AnimatedLoginCard({
    super.key,
    required this.tabController,
    required this.emailCreateController,
    required this.passwordCreateController,
    required this.emailCreateFocusNode,
    required this.passwordCreateFocusNode,
    required this.passwordCreateVisible,
    required this.onPasswordCreateVisibilityChanged,
    required this.isSignUpLoading,
    required this.onSignUp,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.passwordVisible,
    required this.onPasswordVisibilityChanged,
    required this.isSignInLoading,
    required this.onSignIn,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
  });

  @override
  State<AnimatedLoginCard> createState() => _AnimatedLoginCardState();
}

class _AnimatedLoginCardState extends State<AnimatedLoginCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.all(widget.screenWidth * 0.03),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth:
                  widget.isTablet
                      ? widget.screenWidth * 0.6
                      : widget.screenWidth * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 2),
                ),
              ],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 2),
            ),
            child: Column(
              children: [
                LoginTabBar(tabController: widget.tabController),
                SizedBox(
                  height:
                      widget.isTablet
                          ? widget.screenHeight * 0.5
                          : widget.screenHeight * 0.55,
                  child: TabBarView(
                    controller: widget.tabController,
                    children: [
                      CreateAccountTab(
                        emailController: widget.emailCreateController,
                        passwordController: widget.passwordCreateController,
                        emailFocusNode: widget.emailCreateFocusNode,
                        passwordFocusNode: widget.passwordCreateFocusNode,
                        passwordVisible: widget.passwordCreateVisible,
                        onPasswordVisibilityChanged:
                            widget.onPasswordCreateVisibilityChanged,
                        isLoading: widget.isSignUpLoading,
                        onSubmit: widget.onSignUp,
                        screenWidth: widget.screenWidth,
                      ),
                      SignInTab(
                        emailController: widget.emailController,
                        passwordController: widget.passwordController,
                        emailFocusNode: widget.emailFocusNode,
                        passwordFocusNode: widget.passwordFocusNode,
                        passwordVisible: widget.passwordVisible,
                        onPasswordVisibilityChanged:
                            widget.onPasswordVisibilityChanged,
                        isLoading: widget.isSignInLoading,
                        onSubmit: widget.onSignIn,
                        screenWidth: widget.screenWidth,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
