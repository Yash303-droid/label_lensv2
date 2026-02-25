import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/auth_service.dart';
import 'package:label_lensv2/neopop_button.dart';
import 'dart:math' as math;
import 'package:label_lensv2/user_profile.dart';
import 'package:label_lensv2/scan_result.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.wait([
      _authService.getUserProfile(),
      _authService.getScanHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.slate900 : AppColors.slate50,
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: isDarkMode ? AppColors.white : AppColors.slate900));
          }

          UserProfile? userProfile;
          List<ScanHistoryItem> history = [];

          if (snapshot.hasData) {
            // The API calls can fail individually, so we check the types.
            if (snapshot.data![0] is UserProfile) {
              userProfile = snapshot.data![0] as UserProfile;
            }
            if (snapshot.data![1] is List<ScanHistoryItem>) {
              history = snapshot.data![1] as List<ScanHistoryItem>;
            }
          }

          final safeCount = history.where((item) => item.result.safe).length;
          final unsafeCount = history.length - safeCount;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0).copyWith(top: MediaQuery.of(context).padding.top + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainBanner(context, isDarkMode, userProfile),
                const SizedBox(height: 24),
                _buildStatsRow(context, isDarkMode, safeCount, unsafeCount),
                const SizedBox(height: 32),
                _buildRecentScans(context, isDarkMode, history),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainBanner(BuildContext context, bool isDarkMode, UserProfile? userProfile) {
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
                'Hi, ${userProfile?.name ?? 'User'}!',
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
                  onPressed: () {
                    // This should be handled by the parent widget managing the BottomNavBar
                  },
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

  Widget _buildStatsRow(BuildContext context, bool isDarkMode, int safeCount, int unsafeCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(isDarkMode,
              color: AppColors.emerald300,
              icon: Icons.check_circle_outline,
              label: 'SAFE ITEMS',
              value: safeCount.toString(),
              labelColor: AppColors.emerald900,
              rotation: -3),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(isDarkMode,
              color: AppColors.rose300,
              icon: Icons.cancel_outlined,
              label: 'FLAGGED ITEMS',
              value: unsafeCount.toString(),
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

  Widget _buildRecentScans(BuildContext context, bool isDarkMode, List<ScanHistoryItem> history) {
    final recentScans = history.take(2).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('RECENT SCANS', style: AppStyles.heading1.copyWith(fontSize: 16, color: isDarkMode ? AppColors.white : AppColors.slate900)),
            SizedBox(
              height: 32,
              child: NeopopButton(
                onPressed: () { },
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
        if (recentScans.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.slate800 : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: AppStyles.getBorder(isDarkMode),
            ),
            child: Center(
              child: Text(
                'Your recent scans will appear here.',
                style: AppStyles.body.copyWith(color: isDarkMode ? AppColors.slate400 : AppColors.slate500),
              ),
            ),
          )
        else
          ...recentScans.map((item) => _buildRecentScanItem(context, item, isDarkMode)),
      ],
    );
  }

  Widget _buildRecentScanItem(BuildContext context, ScanHistoryItem item, bool isDarkMode) {
    final result = item.result;
    final severity = result.severity.toLowerCase();
    final statusColor = result.safe ? AppColors.emerald400 : (severity == 'critical' ? AppColors.rose400 : AppColors.amber300);

    return GestureDetector(
      onTap: () => _showHistoryDetailDialog(context, item, isDarkMode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.slate800 : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor, width: 2),
          boxShadow: [AppStyles.getShadow(isDarkMode)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.productName,
                    style: AppStyles.bodyBold.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDarkMode ? AppColors.white : AppColors.slate900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().add_jm().format(item.createdAt.toLocal()),
                    style: AppStyles.body.copyWith(
                      fontSize: 12,
                      color: isDarkMode ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.chevron_right, color: isDarkMode ? AppColors.slate400 : AppColors.slate500),
          ],
        ),
      ),
    );
  }

  void _showHistoryDetailDialog(BuildContext context, ScanHistoryItem item, bool isDarkMode) {
    // This logic is duplicated from HistoryScreen. For a larger app, consider refactoring into a shared widget.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.slate800 : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: AppStyles.getBorderSide(isDarkMode, width: 2),
          ),
          title: Text(item.result.productName, style: AppStyles.heading1, textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(item.result.summary, textAlign: TextAlign.center, style: AppStyles.body),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: isDarkMode ? AppColors.indigo300 : AppColors.indigo500),
              ),
            ),
          ],
        );
      },
    );
  }
}