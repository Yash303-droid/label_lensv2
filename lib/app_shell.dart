import 'package:flutter/material.dart';
import 'package:label_lensv2/bottom_nav_bar.dart';
import 'package:label_lensv2/history_screen.dart';
import 'package:label_lensv2/home_screen.dart';
import 'package:label_lensv2/main_app_header.dart';
import 'package:label_lensv2/profile_screen.dart';
import 'package:label_lensv2/saved_screen.dart';
import 'package:label_lensv2/scan_screen.dart';
import 'package:label_lensv2/setup_screen.dart';



class AppShell extends StatefulWidget {
  final VoidCallback toggleTheme;
  const AppShell({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _AppShellState createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final GlobalKey<ProfileScreenState> _profileScreenKey = GlobalKey<ProfileScreenState>();
  final GlobalKey<ScanScreenState> _scanScreenKey = GlobalKey<ScanScreenState>();

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      const HomeScreen(),
      const HistoryScreen(),
      ScanScreen(key: _scanScreenKey),
      const SavedScreen(),
      ProfileScreen(key: _profileScreenKey, toggleTheme: widget.toggleTheme),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2 && _selectedIndex == 2) {
      // If scan tab is tapped while already on it, trigger the scan action.
      // This is valid for both camera and gallery modes.
      _scanScreenKey.currentState?.startProcessing();
      return;
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'History';
      case 2:
        return 'Scan';
      case 3:
        return 'Saved';
      case 4:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false, // Custom nav bar handles bottom safe area
        child: Column(
          children: [
            MainAppHeader(
              title: _getTitleForIndex(_selectedIndex),
              toggleTheme: widget.toggleTheme,
              onProfilePressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SetupScreen(toggleTheme: widget.toggleTheme, isEditMode: true),
                )).then((wasProfileUpdated) {
                  if (wasProfileUpdated == true) {
                    _profileScreenKey.currentState?.fetchUserProfile();
                  }
                });
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: BottomNavBar(
                      selectedIndex: _selectedIndex,
                      onItemTapped: _onItemTapped,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}