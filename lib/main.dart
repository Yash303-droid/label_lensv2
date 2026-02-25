import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_shell.dart';
import 'package:label_lensv2/auth_screen.dart';
import 'package:label_lensv2/auth_service.dart';


void main() {
  // Ensure that plugin services are initialized so that `flutter_secure_storage` works.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (mounted) {
      setState(() {
        _initialScreen = isLoggedIn
            ? AppShell(toggleTheme: _toggleTheme)
            : AuthScreen(toggleTheme: _toggleTheme);
        _isLoading = false;
      });
    }
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Label Lens',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.slate50,
        fontFamily: 'System',
        colorScheme: const ColorScheme.light(
          primary: AppColors.indigo500,
          secondary: AppColors.emerald400,
          background: AppColors.slate50,
          surface: AppColors.white,
          onBackground: AppColors.slate900,
          onSurface: AppColors.slate900,
          error: AppColors.rose400,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.slate900,
        fontFamily: 'System',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.indigo400,
          secondary: AppColors.emerald300,
          background: AppColors.slate900,
          surface: AppColors.slate800,
          onBackground: AppColors.slate50,
          onSurface: AppColors.slate50,
          error: AppColors.rose300,
        ),
      ),
      themeMode: _themeMode,
      home: _isLoading
          ? Scaffold(
              backgroundColor: _themeMode == ThemeMode.dark
                  ? AppColors.slate900
                  : AppColors.slate50,
              body: Center(
                child: CircularProgressIndicator(
                  color: _themeMode == ThemeMode.dark
                      ? AppColors.white
                      : AppColors.slate900,
                ),
              ),
            )
          : _initialScreen,
      debugShowCheckedModeBanner: false,
    );
  }
}
