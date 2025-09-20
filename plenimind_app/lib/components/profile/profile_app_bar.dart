import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBackPressed;
  final String? routeToNavigate;

  const ProfileAppBar({super.key, this.onBackPressed, this.routeToNavigate});

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
              size: 30,
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
          const SizedBox(width: 8),
          Text(
            'Create your Profile',
            style: GoogleFonts.interTight(
              fontSize: 22,
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
