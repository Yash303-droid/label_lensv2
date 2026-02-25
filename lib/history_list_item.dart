import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/neopop_button.dart';

class HistoryListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Widget? subtitle;

  const HistoryListItem({Key? key, required this.item, this.subtitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final status = item['status'] as String;
    final statusColor = status == 'safe'
        ? AppColors.emerald300
        : (status == 'danger' ? AppColors.rose300 : AppColors.amber300);
    final statusIcon = status == 'safe'
        ? Icons.check_circle_outline
        : (status == 'danger'
            ? Icons.error_outline
            : Icons.warning_amber_outlined);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: NeopopButton(
        onPressed: () {},
        color: isDarkMode ? AppColors.slate800 : AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                  border: AppStyles.getBorder(isDarkMode, width: 2),
                  boxShadow: [AppStyles.getShadow(isDarkMode, offset: 2)],
                ),
                child: Icon(statusIcon, color: AppColors.slate900, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.0,
                          color: isDarkMode ? AppColors.white : AppColors.slate900),
                    ),
                    const SizedBox(height: 4),
                    subtitle ??
                        Row(
                          children: [
                            Icon(Icons.horizontal_rule,
                                size: 12,
                                color: isDarkMode
                                    ? AppColors.slate300
                                    : AppColors.slate600),
                            const SizedBox(width: 4),
                            Text(
                              item['date'] as String,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode
                                      ? AppColors.slate300
                                      : AppColors.slate600),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.slate700 : AppColors.slate100,
                  borderRadius: BorderRadius.circular(99),
                  border: AppStyles.getBorder(isDarkMode, width: 2),
                ),
                child: Icon(Icons.chevron_right,
                    color: isDarkMode ? AppColors.white : AppColors.slate900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}