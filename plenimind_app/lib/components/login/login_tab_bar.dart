import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginTabBar extends StatelessWidget {
  final TabController tabController;

  const LoginTabBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      child: TabBar(
        controller: tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.interTight(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        tabs: const [Tab(text: 'Create Account'), Tab(text: 'Log In')],
      ),
    );
  }
}
