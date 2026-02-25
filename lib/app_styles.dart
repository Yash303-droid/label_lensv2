import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  static const TextStyle heading1 = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 30,
    letterSpacing: 1.5,
    color: AppColors.slate900,
    fontFamily: 'System',
    height: 1.2,
  );

  static const TextStyle bodyBold = TextStyle(
    fontWeight: FontWeight.w700,
    color: AppColors.slate600,
    fontFamily: 'System',
  );

  static const TextStyle buttonText = TextStyle(
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    color: AppColors.white,
    fontFamily: 'System',
  );

  static const TextStyle body = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: AppColors.slate600,
    fontFamily: 'System',
    height: 1.4,
  );

  static BoxShadow getShadow(bool isDarkMode, {double offset = 4.0}) {
    return BoxShadow(
      color: isDarkMode ? AppColors.black : AppColors.slate900,
      offset: Offset(0, offset),
      blurRadius: 0,
    );
  }

  static Border getBorder(bool isDarkMode, {double width = 2.0}) {
    return Border.all(
      color: isDarkMode ? AppColors.black : AppColors.slate900,
      width: width,
    );
  }

  static BorderSide getBorderSide(bool isDarkMode, {double width = 2.0}) {
    return BorderSide(
      color: isDarkMode ? AppColors.black : AppColors.slate900,
      width: width,
    );
  }
}