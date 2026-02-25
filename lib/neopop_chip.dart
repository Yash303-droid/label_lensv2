import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';

class NeopopChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NeopopChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final positionOffset = isSelected ? 2.0 : 0.0;
    final shadowOffset = isSelected ? 2.0 : 4.0;
    final bgColor = isSelected
        ? AppColors.indigo300
        : (isDarkMode ? AppColors.slate800 : AppColors.white);
    final textColor = isSelected
        ? AppColors.slate900
        : (isDarkMode ? AppColors.slate50 : AppColors.slate900);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, positionOffset, 0),
        constraints: const BoxConstraints(minWidth: 100),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: AppStyles.getBorder(isDarkMode, width: 2),
          boxShadow: [AppStyles.getShadow(isDarkMode, offset: shadowOffset)],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppStyles.bodyBold.copyWith(color: textColor),
        ),
      ),
    );
  }
}