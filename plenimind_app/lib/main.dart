import 'package:flutter/material.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:plenimind_app/pages/profile.dart';
import 'theme/colors_pallet.dart';
import 'pages/splash.dart';
import 'pages/contact.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      home: const SplashPage(),
      routes: {
        SplashPage.routePath: (context) => const SplashPage(),
        LoginPage.routePath: (context) => const LoginPage(),
        ProfilePage.routePath: (context) => const ProfilePage(),
        ContactListPage.routePath: (context) => const ContactListPage(),
      },
    );
  }
}
