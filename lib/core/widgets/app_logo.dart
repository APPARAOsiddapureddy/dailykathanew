import 'package:flutter/material.dart';

import '../../app/theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Daily Katha logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2D5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.saffron.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: CustomPaint(painter: _LogoPainter()),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bookPaint = Paint()..style = PaintingStyle.fill;
    final flamePaint = Paint()..style = PaintingStyle.fill;
    final goldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;

    bookPaint.shader = const LinearGradient(
      colors: [AppColors.maroon, Color(0xFFB91C1C)],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ).createShader(Offset.zero & size);

    flamePaint.shader = const LinearGradient(
      colors: [AppColors.gold, Color(0xFFEA580C)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(Offset.zero & size);

    final leftBook = Path()
      ..moveTo(size.width * 0.50, size.height * 0.76)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.54,
        size.width * 0.20,
        size.height * 0.66,
        size.width * 0.14,
        size.height * 0.44,
      )
      ..lineTo(size.width * 0.48, size.height * 0.57)
      ..close();

    final rightBook = Path()
      ..moveTo(size.width * 0.50, size.height * 0.76)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.54,
        size.width * 0.80,
        size.height * 0.66,
        size.width * 0.86,
        size.height * 0.44,
      )
      ..lineTo(size.width * 0.52, size.height * 0.57)
      ..close();

    final flame = Path()
      ..moveTo(size.width * 0.50, size.height * 0.63)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.40,
        size.width * 0.54,
        size.height * 0.30,
        size.width * 0.49,
        size.height * 0.12,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.34,
        size.width * 0.75,
        size.height * 0.47,
        size.width * 0.54,
        size.height * 0.63,
      )
      ..close();

    final innerFlame = Path()
      ..moveTo(size.width * 0.50, size.height * 0.66)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.50,
        size.width * 0.53,
        size.height * 0.48,
        size.width * 0.50,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.52,
        size.width * 0.61,
        size.height * 0.58,
        size.width * 0.50,
        size.height * 0.66,
      )
      ..close();

    canvas.drawPath(leftBook, bookPaint);
    canvas.drawPath(rightBook, bookPaint);
    canvas.drawPath(flame, flamePaint);
    canvas.drawPath(innerFlame, Paint()..color = const Color(0xFFFFF2D5));

    final centerLine = Path()
      ..moveTo(size.width * 0.50, size.height * 0.77)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.58,
        size.width * 0.50,
        size.height * 0.45,
      );
    canvas.drawPath(centerLine, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
