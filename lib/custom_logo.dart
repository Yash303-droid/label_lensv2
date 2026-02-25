import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';


class CustomLogo extends StatelessWidget {
  final double size;
  const CustomLogo({Key? key, this.size = 24}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: size,
            color: isDarkMode ? AppColors.slate50 : AppColors.slate900,
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Icon(
              Icons.apple,
              size: size * 0.45,
              color: AppColors.emerald500,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(size * 0.05),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning, size: size * 0.35, color: AppColors.rose500),
            ),
          ),
        ],
      ),
    );
  }
}