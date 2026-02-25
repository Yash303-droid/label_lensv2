import 'package:flutter/material.dart';
import 'package:label_lensv2/app_styles.dart';

class NeopopButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final double borderWidth;
  final double shadowOffset;
  final BorderRadius? borderRadius;

  const NeopopButton({
    Key? key,
    required this.child,
    this.onPressed,
    required this.color,
    this.borderWidth = 2.0,
    this.shadowOffset = 4.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  _NeopopButtonState createState() => _NeopopButtonState();
}

class _NeopopButtonState extends State<NeopopButton> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent event) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (widget.onPressed == null) return;
    widget.onPressed?.call();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isPressed = false);
      }
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (widget.onPressed == null) return;
    if (mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final positionOffset = _isPressed ? widget.shadowOffset : 0.0;
    final currentShadowOffset = _isPressed ? 0.0 : widget.shadowOffset;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, positionOffset, 0),
        decoration: BoxDecoration(
            color: widget.color,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            border: AppStyles.getBorder(isDarkMode, width: widget.borderWidth),
            boxShadow: [AppStyles.getShadow(isDarkMode, offset: currentShadowOffset)]),
        child: widget.child,
      ),
    );
  }
}