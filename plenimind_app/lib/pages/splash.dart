import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:plenimind_app/pages/status_page.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static String routePath = '/splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late AuthManager _authManager;

  @override
  void initState() {
    super.initState();
    _authManager = AuthManager();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Aguardar um pouco para que os tokens sejam carregados
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Recarregar tokens do SharedPreferences
    await _authManager.reloadTokens();

    debugPrint(
      '🔍 [SPLASH] Verificando autenticação: ${_authManager.isLoggedIn}',
    );

    if (_authManager.isLoggedIn) {
      debugPrint('✅ [SPLASH] Usuário autenticado - indo para Status Page');
      if (mounted) {
        Navigator.pushReplacementNamed(context, StatusPage.routePath);
      }
    } else {
      debugPrint('❌ [SPLASH] Usuário não autenticado - indo para Login');
      if (mounted) {
        Navigator.pushReplacementNamed(context, LoginPage.routePath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.error,
                        theme.colorScheme.secondary,
                      ],
                      stops: const [0, 0.5, 1],
                      begin: const Alignment(-1, -1),
                      end: const Alignment(1, 1),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.secondary,
                          theme.colorScheme.surface,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: screenHeight * 0.1),
                          child: Text(
                                'PleniMind',
                                style: GoogleFonts.interTight(
                                  fontSize: screenWidth * 0.15,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .scale(
                                begin: const Offset(3, 3),
                                end: const Offset(1, 1),
                              ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                          ),
                          child: Text(
                                'Bem-Estar Inteligente',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: screenWidth * 0.045,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 400.ms)
                              .move(
                                begin: const Offset(0, 30),
                                end: const Offset(0, 0),
                              ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(3, 3), end: const Offset(1, 1)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.04,
              screenHeight * 0.05,
              screenWidth * 0.04,
              screenHeight * 0.1,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                      child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, LoginPage.routePath);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              minimumSize: Size(
                                screenWidth * 0.8,
                                screenHeight * 0.07,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'Começar',
                              style: GoogleFonts.interTight(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 910.ms, duration: 600.ms)
                          .scale(
                            begin: const Offset(0.6, 0.6),
                            end: const Offset(1, 1),
                            curve: Curves.bounceOut,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
