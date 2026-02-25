import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/neopop_button.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final safeAreaPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 72 + safeAreaPadding,
          padding: EdgeInsets.only(bottom: safeAreaPadding, left: 24, right: 24),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.slate800 : AppColors.white,
            border: Border(
              top: BorderSide(
                color: isDarkMode ? AppColors.black : AppColors.slate900,
                width: 4,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildNavItem(context, icon: Icons.home_outlined, label: 'Home', index: 0)),
              Expanded(child: _buildNavItem(context, icon: Icons.history, label: 'Log', index: 1)),
              const SizedBox(width: 64), // Spacer
              Expanded(child: _buildNavItem(context, icon: Icons.bookmark_border, label: 'Saved', index: 3)),
              Expanded(child: _buildNavItem(context, icon: Icons.person_outline, label: 'Profile', index: 4)),
            ],
          ),
        ),
        Positioned(
          top: -40,
          child: _buildFloatingScanButton(context),
        ),
      ],
    );
  }

  Widget _buildFloatingScanButton(BuildContext context) {
    final isScanActive = selectedIndex == 2;
    return SizedBox(
      width: 72,
      height: 72,
      child: NeopopButton(
        onPressed: () => onItemTapped(2),
        color: isScanActive ? AppColors.emerald400 : AppColors.indigo400,
        borderWidth: 4,
        shadowOffset: isScanActive ? 2 : 6,
        borderRadius: BorderRadius.circular(24),
        child: const Center(
          child: Icon(
            Icons.qr_code_scanner,
            size: 36,
            color: AppColors.slate900,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isActive = selectedIndex == index;

    final color = isActive
        ? (isDarkMode ? AppColors.indigo400 : AppColors.indigo500)
        : (isDarkMode ? AppColors.slate300 : AppColors.slate600);

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, isActive ? -4 : 0, 0),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 2.0,
                color: isActive
                    ? (isDarkMode ? AppColors.white : AppColors.slate900)
                    : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}