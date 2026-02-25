import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/custom_logo.dart';
import 'package:label_lensv2/neopop_button.dart';

class MainAppHeader extends StatelessWidget {
  final String title;
  final VoidCallback toggleTheme;
  final VoidCallback onProfilePressed;

  const MainAppHeader({
    Key? key,
    required this.title,
    required this.toggleTheme,
    required this.onProfilePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.slate800 : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? AppColors.black : AppColors.slate900,
            width: 4,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DottedPainter(isDarkMode),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _buildLeftSection(isDarkMode),
              ),
              _buildRightSection(isDarkMode, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSection(bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.indigo400 : AppColors.indigo300,
            borderRadius: BorderRadius.circular(12),
            border: AppStyles.getBorder(isDarkMode, width: 2),
            boxShadow: [AppStyles.getShadow(isDarkMode, offset: 2)],
          ),
          child: const CustomLogo(size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? AppColors.white : AppColors.slate900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightSection(bool isDarkMode, BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: NeopopButton(
            onPressed: toggleTheme,
            color: isDarkMode ? AppColors.amber300 : AppColors.indigo300,
            shadowOffset: 3,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Icon(
                isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: AppColors.slate900,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          height: 48,
          child: NeopopButton(
            onPressed: onProfilePressed,
            color: AppColors.emerald300,
            shadowOffset: 3,
            borderRadius: BorderRadius.circular(12),
            child: const Center(
              child: Icon(
                Icons.person_outline,
                color: AppColors.slate900,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DottedPainter extends CustomPainter {
  final bool isDarkMode;
  _DottedPainter(this.isDarkMode);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.05);
    const double dotRadius = 1.0;
    const double spacing = 24.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}