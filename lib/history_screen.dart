import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/history_list_item.dart';
import 'package:label_lensv2/mock_data_service.dart';
import 'package:label_lensv2/neopop_input.dart';


class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            NeopopInput(
              hint: 'Search past scans...',
              icon: Icons.search,
              textStyle: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.0,
                color: isDarkMode ? AppColors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fullMockHistory.length,
              itemBuilder: (context, index) {
                return HistoryListItem(item: fullMockHistory[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}