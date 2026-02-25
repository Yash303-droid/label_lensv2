import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/history_list_item.dart';
import 'package:label_lensv2/mock_data_service.dart';


class SavedScreen extends StatelessWidget {
  const SavedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildHeaderBanner(context, isDarkMode),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockSavedItems.length,
              itemBuilder: (context, index) {
                return HistoryListItem(
                  item: mockSavedItems[index],
                  subtitle: Row(
                    children: [
                      Icon(Icons.bookmark,
                          size: 12,
                          color: isDarkMode
                              ? AppColors.indigo300
                              : AppColors.indigo500),
                      const SizedBox(width: 4),
                      Text(
                        'SAVED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? AppColors.indigo300
                              : AppColors.indigo500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.indigo900 : AppColors.indigo200,
        borderRadius: BorderRadius.circular(16),
        border: AppStyles.getBorder(isDarkMode, width: 2),
        boxShadow: [AppStyles.getShadow(isDarkMode, offset: 4)],
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: 3 * (math.pi / 180),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.slate800 : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: AppStyles.getBorder(isDarkMode, width: 2),
                boxShadow: [AppStyles.getShadow(isDarkMode, offset: 2)],
              ),
              child: Icon(Icons.bookmark,
                  size: 24,
                  color: isDarkMode ? AppColors.slate50 : AppColors.slate900),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SAVED SCANS',
                    style: AppStyles.heading1.copyWith(
                        fontSize: 24,
                        color:
                            isDarkMode ? AppColors.slate50 : AppColors.slate900)),
                const SizedBox(height: 4),
                Text('YOUR BOOKMARKED ITEMS',
                    style: AppStyles.bodyBold.copyWith(
                        fontSize: 14,
                        letterSpacing: 1.5,
                        color: isDarkMode
                            ? AppColors.slate300
                            : AppColors.slate600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}