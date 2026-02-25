import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';

class NeopopInput extends StatefulWidget {
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final int maxLines;
  final double minHeight;
  final EdgeInsets? contentPadding;
  final TextStyle? textStyle;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const NeopopInput({
    Key? key,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.maxLines = 1,
    this.minHeight = 0,
    this.contentPadding,
    this.textStyle,
    this.controller,
    this.keyboardType,
  }) : super(key: key);

  @override
  _NeopopInputState createState() => _NeopopInputState();
}

class _NeopopInputState extends State<NeopopInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final shadowOffset = _isFocused ? 2.0 : 4.0;
    final positionOffset = _isFocused ? 2.0 : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: Matrix4.translationValues(0, positionOffset, 0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.slate800 : AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: AppStyles.getBorder(isDarkMode, width: 2),
        boxShadow: [AppStyles.getShadow(isDarkMode, offset: shadowOffset)],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.minHeight),
        child: TextField(
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines == 1 ? 1 : null,
          style: widget.textStyle ?? AppStyles.bodyBold.copyWith(color: isDarkMode ? AppColors.white : AppColors.slate900),
          decoration: InputDecoration(
            prefixIcon: widget.icon != null ? Icon(widget.icon, color: isDarkMode ? AppColors.slate300 : AppColors.slate600, size: 24) : null,
            hintText: widget.hint,
            hintStyle: (widget.textStyle ?? AppStyles.bodyBold)
                .copyWith(color: isDarkMode ? AppColors.slate300 : AppColors.slate600),
            contentPadding: widget.contentPadding ?? EdgeInsets.fromLTRB(widget.icon != null ? 12 : 16, 16, 16, 16),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}