// main.dart
import 'package:flutter/material.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:plenimind_app/pages/profile.dart';
import 'package:plenimind_app/pages/splash.dart';
import 'package:plenimind_app/pages/contact.dart';
import 'package:plenimind_app/pages/terms_conditions.dart';
import 'package:plenimind_app/pages/status_page.dart';
import 'package:plenimind_app/theme/colors_pallet.dart';
import 'package:plenimind_app/service/notification_service.dart';
import 'package:plenimind_app/pages/settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ INICIALIZAR SERVIÇOS GLOBAIS
  _initializeGlobalServices();

  runApp(const MyApp());
}

// ✅ FUNÇÃO PARA INICIALIZAR SERVIÇOS GLOBAIS
void _initializeGlobalServices() {
  try {
    debugPrint('🚀 [MAIN] Inicializando serviços globais...');

    // ✅ INICIALIZAR SERVIÇO DE NOTIFICAÇÕES
    NotificationService().initialize();

    debugPrint('✅ [MAIN] Serviços globais inicializados com sucesso');
  } catch (e) {
    debugPrint('❌ [MAIN] Erro ao inicializar serviços globais: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
    );

    return MaterialApp(
      title: 'PleniMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        // ✅ CONFIGURAÇÕES ADICIONAIS PARA MELHOR UX
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        // ✅ CORREÇÃO: Usar CardThemeData em vez de CardTheme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(8),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        // ✅ ADICIONAR OUTRAS CONFIGURAÇÕES OPCIONAIS
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
        ),
      ),
      home: const SplashPage(),
      routes: {
        SplashPage.routePath: (context) => const SplashPage(),
        LoginPage.routePath: (context) => const LoginPage(),
        ProfilePage.routePath: (context) => const ProfilePage(),
        ContactPage.routePath: (context) => const ContactPage(),
        TermsConditionsScreen.routePath:
            (context) => const TermsConditionsScreen(),
        StatusPage.routePath: (context) => const StatusPage(),
        SettingsPage.routePath: (context) => const SettingsPage(),
      },
      // ✅ CONFIGURAÇÕES ADICIONAIS PARA MELHOR PERFORMANCE
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // ✅ REMOVER FOCO AO TOCAR EM QUALQUER LUGAR
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              currentFocus.focusedChild?.unfocus();
            }
          },
          child: child,
        );
      },
    );
  }
}
