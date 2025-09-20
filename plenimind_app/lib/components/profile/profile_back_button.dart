import 'package:flutter/material.dart';

class ProfileBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProfileBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_rounded,
        color: Theme.of(context).textTheme.bodyLarge?.color,
        size: 30,
      ),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(50, 50),
      ),
    );
  }
}
