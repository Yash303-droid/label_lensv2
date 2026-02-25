import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_shell.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/auth_service.dart';
import 'package:label_lensv2/dotted_background.dart';
import 'package:label_lensv2/neopop_button.dart';
import 'package:label_lensv2/neopop_chip.dart';
import 'package:label_lensv2/neopop_input.dart';
import 'package:label_lensv2/user_profile.dart';




class SetupScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isEditMode;
  const SetupScreen({Key? key, required this.toggleTheme, this.isEditMode = false}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _authService = AuthService();
  final _ageController = TextEditingController();
  final _likesController = TextEditingController();
  final _dislikesController = TextEditingController();
  final _nameController = TextEditingController();

  int _currentStep = 1;
  bool _isLoading = false;
  bool _isPageLoading = false;
  String? _selectedGender;
  final Set<String> _selectedDiets = {};
  final Set<String> _selectedAllergies = {};
  final Set<String> _selectedHealthIssues = {};
  
  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _isPageLoading = true;
      _fetchAndPopulateProfile();
    }
  }

  Future<void> _fetchAndPopulateProfile() async {
    try {
      final UserProfile userProfile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _nameController.text = userProfile.name;
          _ageController.text = userProfile.age?.toString() ?? '';
          if (userProfile.gender != null) {
            _selectedGender = userProfile.gender![0].toUpperCase() + userProfile.gender!.substring(1);
          }
          if (userProfile.diet != null) {
            _selectedDiets.add(userProfile.diet!);
          }
          if (userProfile.allergies != null) {
            _selectedAllergies.addAll(userProfile.allergies!);
          }
          if (userProfile.healthIssues != null) {
            _selectedHealthIssues.addAll(userProfile.healthIssues!);
          }
          _likesController.text = userProfile.likes?.join(', ') ?? '';
          _dislikesController.text = userProfile.dislikes?.join(', ') ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.rose400,
          content: Text(e.toString().replaceFirst('Exception: ', ''), style: AppStyles.bodyBold.copyWith(color: AppColors.slate900)),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isPageLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _likesController.dispose();
    _dislikesController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _finishSetup() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final success = await _authService.updateProfile(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        diet: _selectedDiets.isNotEmpty ? _selectedDiets.first : null,
        allergies: _selectedAllergies.toList(),
        healthIssues: _selectedHealthIssues.toList(),
        likes: _likesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        dislikes: _dislikesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );

      if (success && mounted) {
        if (widget.isEditMode) {
          Navigator.of(context).pop(true); // Pop with a result to indicate success
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => AppShell(toggleTheme: widget.toggleTheme),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.rose400,
          content: Text(e.toString().replaceFirst('Exception: ', ''), style: AppStyles.bodyBold.copyWith(color: AppColors.slate900)),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _finishSetup();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.indigo950 : AppColors.indigo50,
      body: DottedBackground(
        child: SafeArea(
          child: _isPageLoading
              ? Center(child: CircularProgressIndicator(color: isDarkMode ? AppColors.white : AppColors.slate900))
              : Stack(
                  children: [
                    Column(
                      children: [
                        _buildProgressHeader(isDarkMode),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildStepContent(isDarkMode),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildThemeToggleButton(isDarkMode),
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

  Widget _buildProgressHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.slate800 : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: AppStyles.getBorder(isDarkMode, width: 4),
          boxShadow: [AppStyles.getShadow(isDarkMode, offset: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SETUP $_currentStep/3',
              style: AppStyles.heading1.copyWith(
                fontSize: 24,
                color: isDarkMode ? AppColors.white : AppColors.slate900,
              ),
            ),
            Row(
              children: List.generate(3, (index) {
                final isActive = index < _currentStep;
                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.emerald400 : (isDarkMode ? AppColors.slate800 : AppColors.slate50),
                    shape: BoxShape.circle,
                    border: AppStyles.getBorder(isDarkMode, width: 2),
                    boxShadow: isActive ? [AppStyles.getShadow(isDarkMode)] : [],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDarkMode) {
    switch (_currentStep) {
      case 1:
        return _buildStep1(isDarkMode);
      case 2:
        return _buildStep2(isDarkMode);
      case 3:
        return _buildStep3(isDarkMode);
      default:
        return Container();
    }
  }

  Widget _buildMainCard(bool isDarkMode, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.slate800 : AppColors.white,
        borderRadius: BorderRadius.circular(32),
        border: AppStyles.getBorder(isDarkMode, width: 4),
        boxShadow: [AppStyles.getShadow(isDarkMode, offset: 8)],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(bool isDarkMode, {IconData? icon, required String title, double letterSpacing = 1.5}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 24, color: isDarkMode ? AppColors.white : AppColors.slate900),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: letterSpacing,
            color: isDarkMode ? AppColors.white : AppColors.slate900,
            fontFamily: 'System',
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(bool isDarkMode) {
    return _buildMainCard(
      isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(isDarkMode, icon: Icons.person_pin_circle_outlined, title: 'BASIC INFO'),
          const SizedBox(height: 24),
          NeopopInput(controller: _nameController, hint: 'Name', icon: Icons.person_outline),
          const SizedBox(height: 16),
          NeopopInput(controller: _ageController, hint: 'Age', icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          _buildSectionHeader(isDarkMode, title: 'GENDER', letterSpacing: 2.0),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildGenderButton(isDarkMode, 'Male'),
              const SizedBox(width: 12),
              _buildGenderButton(isDarkMode, 'Female'),
              const SizedBox(width: 12),
              _buildGenderButton(isDarkMode, 'Other'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: NeopopButton(
              onPressed: _nextStep,
              color: AppColors.emerald400,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('NEXT STEP', style: AppStyles.buttonText.copyWith(color: AppColors.slate900)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: AppColors.slate900),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(bool isDarkMode, String gender) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: SizedBox(
        height: 48,
        child: GestureDetector(
          onTap: () => setState(() => _selectedGender = gender),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(0, isSelected ? 2 : 0, 0),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.indigo300 : (isDarkMode ? AppColors.slate800 : AppColors.slate50),
              borderRadius: BorderRadius.circular(12),
              border: AppStyles.getBorder(isDarkMode, width: 2),
              boxShadow: [AppStyles.getShadow(isDarkMode, offset: isSelected ? 2 : 4)],
            ),
            child: Center(
              child: Text(
                gender.toUpperCase(),
                style: AppStyles.bodyBold.copyWith(color: isDarkMode ? AppColors.white : AppColors.slate900),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(bool isDarkMode) {
    final diets = ['Vegan', 'Vegetarian', 'Keto', 'Paleo'];
    final allergies = ['Peanuts', 'Tree Nuts', 'Dairy', 'Eggs', 'Soy', 'Gluten'];
    final healthIssues = ['Diabetes', 'IBS', 'PCOS', 'Hypertension'];

    return _buildMainCard(
      isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(isDarkMode, icon: Icons.eco_outlined, title: 'DIET'),
          const SizedBox(height: 16),
          _buildChipGroup(diets, _selectedDiets, isSingleSelect: true),
          const SizedBox(height: 24),
          _buildSectionHeader(isDarkMode, icon: Icons.warning_amber_outlined, title: 'ALLERGIES'),
          const SizedBox(height: 16),
          _buildChipGroup(allergies, _selectedAllergies),
          const SizedBox(height: 24),
          _buildSectionHeader(isDarkMode, icon: Icons.monitor_heart_outlined, title: 'HEALTH ISSUES'),
          const SizedBox(height: 16),
          _buildChipGroup(healthIssues, _selectedHealthIssues),
          const SizedBox(height: 32),
          Row(
            children: [
              SizedBox(
                height: 56,
                width: 80,
                child: NeopopButton(
                  onPressed: _prevStep,
                  color: isDarkMode ? AppColors.slate800 : AppColors.white,
                  child: Center(child: Icon(Icons.chevron_left, color: isDarkMode ? AppColors.white : AppColors.slate900)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: NeopopButton(
                    onPressed: _nextStep,
                    color: AppColors.emerald400,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('NEXT', style: AppStyles.buttonText.copyWith(color: AppColors.slate900)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_right, color: AppColors.slate900),
                        ],
                      ),
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

  Widget _buildChipGroup(List<String> options, Set<String> selectedOptions, {bool isSingleSelect = false}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        return NeopopChip(
          label: option,
          isSelected: selectedOptions.contains(option.toLowerCase()),
          onTap: () {
            setState(() {
              final lowerCaseOption = option.toLowerCase();
              if (isSingleSelect) {
                if (selectedOptions.contains(lowerCaseOption)) {
                  selectedOptions.clear();
                } else {
                  selectedOptions.clear();
                  selectedOptions.add(lowerCaseOption);
                }
              } else {
                if (selectedOptions.contains(lowerCaseOption)) {
                  selectedOptions.remove(lowerCaseOption);
                } else {
                  selectedOptions.add(lowerCaseOption);
                }
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStep3(bool isDarkMode) {
    return _buildMainCard(
      isDarkMode,
      child: Column(
        children: [
          _buildTextArea(isDarkMode, controller: _likesController, icon: Icons.thumb_up_alt_outlined, iconBgColor: AppColors.emerald300, hint: 'List any foods you like...'),
          const SizedBox(height: 24),
          _buildTextArea(isDarkMode, controller: _dislikesController, icon: Icons.thumb_down_alt_outlined, iconBgColor: AppColors.rose400, hint: 'List any foods you dislike...'),
          const SizedBox(height: 32),
          Row(
            children: [
              SizedBox(
                height: 56,
                width: 80,
                child: NeopopButton(
                  onPressed: _prevStep,
                  color: isDarkMode ? AppColors.slate800 : AppColors.white,
                  child: Center(child: Icon(Icons.chevron_left, color: isDarkMode ? AppColors.white : AppColors.slate900)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: NeopopButton(
                    onPressed: _nextStep,
                    color: AppColors.indigo500,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('FINISH', style: AppStyles.buttonText),
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle_outline, color: AppColors.white),
                              ],
                            ),
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

  Widget _buildTextArea(bool isDarkMode, {required IconData icon, required Color iconBgColor, required String hint, TextEditingController? controller}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: NeopopInput(
            controller: controller,
            hint: hint,
            minHeight: 120,
            maxLines: 5,
            contentPadding: const EdgeInsets.fromLTRB(56, 16, 16, 16),
          ),
        ),
        Positioned(
          top: 0,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
              border: AppStyles.getBorder(isDarkMode, width: 2),
              boxShadow: [AppStyles.getShadow(isDarkMode, offset: 2)],
            ),
            child: Icon(icon, color: AppColors.slate900, size: 20),
          ),
        ),
      ],
    );
  }
}