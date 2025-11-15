import 'package:flutter/material.dart';
import 'package:plenimind_app/theme/colors_pallet.dart';

class TermsAcceptance extends StatelessWidget {
  final bool isAccepted;
  final ValueChanged<bool> onChanged;

  const TermsAcceptance({
    super.key,
    required this.isAccepted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        value: isAccepted,
        onChanged: (bool? value) => onChanged(value ?? false),
        title: Text(
          'Autorizo coleta de dados biométricos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        activeColor: AppColors.success,
        checkColor: AppColors.onPrimary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
