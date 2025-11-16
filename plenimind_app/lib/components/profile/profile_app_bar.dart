import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBackPressed;
  final String? routeToNavigate;
  final double screenWidth;

  const ProfileAppBar({
    super.key,
    this.onBackPressed,
    this.routeToNavigate,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              size: screenWidth * 0.075,
            ),
            onPressed: () {
              if (onBackPressed != null) {
                onBackPressed!();
              } else if (routeToNavigate != null) {
                Navigator.pushReplacementNamed(context, routeToNavigate!);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            'Criar seu Perfil',
            style: GoogleFonts.interTight(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
