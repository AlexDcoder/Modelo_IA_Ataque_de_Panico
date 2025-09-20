import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plenimind_app/pages/login.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static String routeName = 'splash';
  static String routePath = '/splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
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
                        theme.colorScheme.tertiary,
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
                          padding: const EdgeInsets.only(top: 44),
                          child: Text(
                                'PleniMind',
                                style: GoogleFonts.interTight(
                                  fontSize: 76,
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
                          padding: const EdgeInsets.symmetric(horizontal: 44),
                          child: Text(
                                'Bem-Estar Inteligente',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
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
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 44),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, LoginPage.routePath);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              minimumSize: const Size(330, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'Começar',
                              style: GoogleFonts.interTight(
                                fontSize: 18,
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
