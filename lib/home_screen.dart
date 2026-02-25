import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/auth_service.dart';
import 'package:label_lensv2/history_list_item.dart';
import 'package:label_lensv2/mock_data_service.dart';


import 'package:label_lensv2/neopop_button.dart';
import 'dart:math' as math;

import 'package:label_lensv2/user_profile.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userProfile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // On home screen, we can fail silently and just show a default name.
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: isDarkMode ? AppColors.white : AppColors.slate900))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainBanner(context, isDarkMode),
                    const SizedBox(height: 24),
                    _buildStatsRow(context, isDarkMode),
                    const SizedBox(height: 32),
                    _buildRecentScans(context, isDarkMode),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainBanner(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.indigo400,
        borderRadius: BorderRadius.circular(24),
        border: AppStyles.getBorder(isDarkMode, width: 4),
        boxShadow: [AppStyles.getShadow(isDarkMode, offset: 8)],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            bottom: -50,
            child: Icon(
              Icons.apple,
              size: 140,
              color: AppColors.white.withOpacity(0.4),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBadge(isDarkMode),
              const SizedBox(height: 16),
              Text(
                'Hi, ${_userProfile?.name ?? 'User'}!',
                style: AppStyles.heading1.copyWith(color: AppColors.slate900),
              ),
              const SizedBox(height: 4),
              const Text(
                'What are we checking today?',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.indigo900),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: NeopopButton(
                  onPressed: () {},
                  color: AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, color: AppColors.slate900),
                        const SizedBox(width: 12),
                        Text(
                          'Scan New Label',
                          style: AppStyles.buttonText.copyWith(color: AppColors.slate900),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(99),
        border: AppStyles.getBorder(isDarkMode, width: 2),
        boxShadow: [AppStyles.getShadow(isDarkMode, offset: 2)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.show_chart, color: AppColors.slate900, size: 14),
          const SizedBox(width: 6),
          Text(
            'SCANNER READY',
            style: TextStyle(
              color: AppColors.slate900,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(isDarkMode,
              color: AppColors.emerald300,
              icon: Icons.check_circle_outline,
              label: 'SAFE ITEMS',
              value: '42',
              labelColor: AppColors.emerald900,
              rotation: -3),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(isDarkMode,
              color: AppColors.rose300,
              icon: Icons.cancel_outlined,
              label: 'FLAGGED ITEMS',
              value: '8',
              labelColor: AppColors.rose900,
              rotation: 3),
        ),
      ],
    );
  }

  Widget _buildStatCard(bool isDarkMode,
      {required Color color,
      required IconData icon,
      required String label,
      required String value,
      required Color labelColor,
      required double rotation}) {
    return Transform.rotate(
      angle: rotation * (math.pi / 180),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: AppStyles.getBorder(isDarkMode, width: 2),
          boxShadow: [AppStyles.getShadow(isDarkMode, offset: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: AppStyles.getBorder(isDarkMode, width: 2),
                boxShadow: [AppStyles.getShadow(isDarkMode, offset: 2)],
              ),
              child: Icon(icon, color: AppColors.slate900, size: 24),
            ),
            const SizedBox(height: 12),
            Text(value, style: AppStyles.heading1.copyWith(fontSize: 36, color: AppColors.slate900)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: labelColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScans(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Recent Scans', style: AppStyles.heading1.copyWith(fontSize: 20, color: isDarkMode ? AppColors.white : AppColors.slate900)),
            SizedBox(
              height: 32,
              child: NeopopButton(
                onPressed: () {},
                color: isDarkMode ? AppColors.slate800 : AppColors.white,
                shadowOffset: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'VIEW ALL',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isDarkMode ? AppColors.white : AppColors.slate900),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...recentMockHistory.map((item) => HistoryListItem(item: item)).toList(),
      ],
    );
  }
}