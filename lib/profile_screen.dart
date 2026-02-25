import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/auth_service.dart';
import 'package:label_lensv2/auth_screen.dart';

import 'package:label_lensv2/neopop_button.dart';
import 'package:label_lensv2/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ProfileScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
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
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AuthScreen(toggleTheme: widget.toggleTheme)),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: isDarkMode ? AppColors.white : AppColors.slate900))
          : _error != null
              ? Center(child: Text('Error: $_error', style: TextStyle(color: AppColors.rose400)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildProfileHeader(context, isDarkMode),
                      const SizedBox(height: 24),
                      _buildProfileDetails(context, isDarkMode),
                      const SizedBox(height: 24),
                      _buildSettingsMenu(context, isDarkMode),
                      const SizedBox(height: 24),
                      _buildSignOutButton(context, isDarkMode),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.indigo400,
        borderRadius: BorderRadius.circular(32),
        border: AppStyles.getBorder(isDarkMode, width: 4),
        boxShadow: [AppStyles.getShadow(isDarkMode, offset: 8)],
      ),
      child: Column(
        children: [
          _Avatar(),
          const SizedBox(height: 16),
          Text(
            _userProfile?.name.toUpperCase() ?? 'USER',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatusBadge(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.emerald300,
        borderRadius: BorderRadius.circular(12),
        border: AppStyles.getBorder(isDarkMode, width: 2),
        boxShadow: [AppStyles.getShadow(isDarkMode, offset: 2)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: AppColors.slate900),
          SizedBox(width: 8),
          Text(
            'VERIFIED',
            style: TextStyle(
              color: AppColors.slate900,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(BuildContext context, bool isDarkMode) {
    if (_userProfile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.slate800 : AppColors.white,
        borderRadius: BorderRadius.circular(32),
        border: AppStyles.getBorder(isDarkMode, width: 4),
        boxShadow: [AppStyles.getShadow(isDarkMode, offset: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR DETAILS',
            style: AppStyles.heading1.copyWith(
              fontSize: 20,
              color: isDarkMode ? AppColors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow(isDarkMode, Icons.email_outlined, 'Email', _userProfile!.email),
          _buildDetailRow(isDarkMode, Icons.cake_outlined, 'Age', _userProfile!.age?.toString()),
          _buildDetailRow(isDarkMode, Icons.person_search_outlined, 'Gender', _userProfile!.gender),
          _buildDetailRow(isDarkMode, Icons.eco_outlined, 'Diet', _userProfile!.diet),
        ],
      ),
    );
  }

  Widget _buildDetailRow(bool isDarkMode, IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isDarkMode ? AppColors.slate300 : AppColors.slate600, size: 20),
          const SizedBox(width: 16),
          Text(
            '$label:',
            style: AppStyles.bodyBold.copyWith(color: isDarkMode ? AppColors.slate300 : AppColors.slate600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value[0].toUpperCase() + value.substring(1),
              style: AppStyles.bodyBold.copyWith(
                fontWeight: FontWeight.w900,
                color: isDarkMode ? AppColors.white : AppColors.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.slate800 : AppColors.white,
        borderRadius: BorderRadius.circular(32),
        border: AppStyles.getBorder(isDarkMode, width: 4),
        boxShadow: [AppStyles.getShadow(isDarkMode, offset: 8)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            _MenuItem(
              isDarkMode: isDarkMode,
              icon: Icons.settings_outlined,
              text: 'Scanner Settings',
              iconBgColor: AppColors.indigo200,
            ),
            _MenuItem(
              isDarkMode: isDarkMode,
              icon: Icons.download_for_offline_outlined,
              text: 'Data Export',
              iconBgColor: AppColors.emerald200,
            ),
            _MenuItem(
              isDarkMode: isDarkMode,
              icon: Icons.support_agent_outlined,
              text: 'System Support',
              iconBgColor: AppColors.amber200,
              hasBottomBorder: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, bool isDarkMode) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: NeopopButton(
        onPressed: _handleLogout,
        color: AppColors.rose400,
        child: Center(
          child: Text(
            'TERMINATE SESSION',
            style: AppStyles.buttonText.copyWith(
              color: AppColors.slate900,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatefulWidget {
  @override
  _AvatarState createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final rotation = _isHovered ? 6.0 : 3.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.rotationZ(rotation * math.pi / 180),
        transformAlignment: Alignment.center,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.slate800 : AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: AppStyles.getBorder(isDarkMode, width: 4),
            boxShadow: [AppStyles.getShadow(isDarkMode, offset: 4)],
          ),
          child: Icon(
            Icons.person_outline,
            size: 48,
            color: isDarkMode ? AppColors.slate300 : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final bool isDarkMode;
  final IconData icon;
  final String text;
  final Color iconBgColor;
  final bool hasBottomBorder;

  const _MenuItem({
    required this.isDarkMode,
    required this.icon,
    required this.text,
    required this.iconBgColor,
    this.hasBottomBorder = true,
  });

  @override
  _MenuItemState createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        onHover: (hovering) => setState(() => _isHovered = hovering),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovered ? (widget.isDarkMode ? AppColors.slate700 : AppColors.slate100) : Colors.transparent,
            border: widget.hasBottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: widget.isDarkMode ? AppColors.black : AppColors.slate900,
                      width: 4,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: AppStyles.getBorder(widget.isDarkMode, width: 2),
                  boxShadow: [AppStyles.getShadow(widget.isDarkMode, offset: 2)],
                ),
                child: Icon(widget.icon, size: 20, color: AppColors.slate900),
              ),
              const SizedBox(width: 16),
              Text(
                widget.text.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: widget.isDarkMode ? AppColors.white : AppColors.slate900,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: widget.isDarkMode ? AppColors.white : AppColors.slate900,
              ),
            ],
          ),
        ),
      ),
    );
  }
}