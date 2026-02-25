import 'package:flutter/material.dart';

class DottedBackground extends StatelessWidget {
  final Widget child;
  final Color? dotColor;
  const DottedBackground({Key? key, required this.child, this.dotColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final finalDotColor = dotColor ?? (isDarkMode ? Colors.white : Colors.black).withOpacity(0.05);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _DottedPainter(finalDotColor),
          ),
        ),
        child,
      ],
    );
  }
}

class _DottedPainter extends CustomPainter {
  final Color dotColor;
  _DottedPainter(this.dotColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;

    const double dotRadius = 1.0;
    const double spacing = 24.0;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}