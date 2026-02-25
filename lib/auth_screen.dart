import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_shell.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/dotted_background.dart';
import 'package:label_lensv2/neopop_button.dart';
import 'package:label_lensv2/neopop_input.dart';
import 'package:label_lensv2/auth_service.dart';

import 'package:label_lensv2/setup_screen.dart';


class AuthScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const AuthScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.indigo950 : AppColors.indigo50,
      body: DottedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              _buildFloatingElement(
                size,
                isDarkMode,
                child: Icon(Icons.apple, color: AppColors.slate900, size: 48),
                color: AppColors.emerald300,
                size: 96,
                alignment: Alignment.topLeft,
                rotation: 12,
              ),
              _buildFloatingElement(
                size,
                isDarkMode,
                child: Icon(Icons.warning_amber_rounded, color: AppColors.slate900, size: 40),
                color: AppColors.rose400,
                size: 80,
                alignment: Alignment.topRight,
                rotation: -12,
                isSquare: true,
              ),
              Positioned(
                top: 16,
                right: 16,
                child: _buildThemeToggleButton(isDarkMode),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildAuthCard(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleButton(bool isDarkMode) {
    return NeopopButton(
      onPressed: widget.toggleTheme,
      color: isDarkMode ? AppColors.amber300 : AppColors.indigo300,
      shadowOffset: 3,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Icon(
          isDarkMode ? Icons.light_mode : Icons.dark_mode,
          color: AppColors.slate900,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildFloatingElement(Size screenSize, bool isDarkMode,
      {required Widget child,
      required Color color,
      required double size,
      required Alignment alignment,
      double rotation = 0,
      bool isSquare = false}) {
    return Positioned(
      top: alignment.y > 0 ? null : screenSize.height * 0.1,
      left: alignment.x > 0 ? null : screenSize.width * 0.05,
      right: alignment.x < 0 ? null : screenSize.width * 0.05,
      child: Transform.rotate(
        angle: rotation * 3.14159 / 180,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: isSquare ? BorderRadius.circular(16) : BorderRadius.circular(size / 2),
            border: AppStyles.getBorder(isDarkMode, width: 4),
            boxShadow: [AppStyles.getShadow(isDarkMode, offset: 4)],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAuthCard(bool isDarkMode) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 40),
          padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.slate800 : AppColors.white,
            borderRadius: BorderRadius.circular(32),
            border: AppStyles.getBorder(isDarkMode, width: 4),
            boxShadow: [AppStyles.getShadow(isDarkMode, offset: 8)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isLogin ? 'Welcome Back!' : 'Start Scanning!',
                style: AppStyles.heading1.copyWith(color: isDarkMode ? AppColors.white : AppColors.slate900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your details to continue',
                style: AppStyles.bodyBold.copyWith(color: isDarkMode ? AppColors.slate300 : AppColors.slate600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeopopInput(controller: _emailController, icon: Icons.mail_outline, hint: 'Email'),
              const SizedBox(height: 16),
              NeopopInput(controller: _passwordController, icon: Icons.lock_outline, hint: 'Password', obscureText: true),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: NeopopButton(
                  onPressed: () async {
                    if (_isLoading) return;

                    setState(() => _isLoading = true);

                    try {
                      if (_isLogin) {
                        final success = await _authService.login(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                        );
                        if (success && mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => AppShell(toggleTheme: widget.toggleTheme),
                            ),
                          );
                        }
                      } else {
                        final success = await _authService.register(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                        );
                        if (success && mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) =>
                                  SetupScreen(toggleTheme: widget.toggleTheme),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.rose400,
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                              style: AppStyles.bodyBold.copyWith(color: AppColors.slate900),
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  color: AppColors.indigo500,
                  shadowOffset: 4,
                  borderWidth: 2,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Center(
                          child: Text(_isLogin ? 'SECURE LOGIN' : 'CREATE PROFILE', style: AppStyles.buttonText),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _buildToggleLink(isDarkMode),
            ],
          ),
        ),
        Positioned(
          top: -8,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.indigo300,
              borderRadius: BorderRadius.circular(24),
              border: AppStyles.getBorder(isDarkMode, width: 4),
              boxShadow: [AppStyles.getShadow(isDarkMode, offset: 4)],
            ),
            child: const Icon(Icons.qr_code_scanner, color: AppColors.slate900, size: 40),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleLink(bool isDarkMode) {
    return RichText(
      text: TextSpan(
        style: AppStyles.bodyBold.copyWith(color: isDarkMode ? AppColors.slate300 : AppColors.slate600),
        children: [
          TextSpan(text: _isLogin ? "Don't have an account? " : "Already have an account? "),
          TextSpan(
            text: _isLogin ? 'Sign Up' : 'Log In',
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.indigo500),
            recognizer: TapGestureRecognizer()..onTap = _toggleAuthMode,
          ),
        ],
      ),
    );
  }
}