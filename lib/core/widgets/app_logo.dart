import 'package:flutter/material.dart';

import '../../app/theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.glow = 0.16});

  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Daily Katha logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.saffron.withValues(alpha: glow),
              blurRadius: size * 0.22,
              offset: Offset(0, size * 0.08),
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
    final rect = Offset.zero & size;
    final ivoryPaint = Paint()..color = const Color(0xFFFFF7E6);
    final lowerBookPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0xFF8B1218), Color(0xFFB91C1C)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect);
    final goldPagePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0xFFF5B316), AppColors.gold],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect);
    final flamePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0xFFEA580C), Color(0xFFFF8A00)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(rect);
    final innerFlamePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [AppColors.gold, Color(0xFFFFC928)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(rect);

    final leftLowerBook = Path()
      ..moveTo(size.width * 0.50, size.height * 0.88)
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.72,
        size.width * 0.24,
        size.height * 0.79,
        size.width * 0.14,
        size.height * 0.66,
      )
      ..lineTo(size.width * 0.08, size.height * 0.51)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.55,
        size.width * 0.43,
        size.height * 0.57,
        size.width * 0.50,
        size.height * 0.82,
      )
      ..close();

    final rightLowerBook = Path()
      ..moveTo(size.width * 0.50, size.height * 0.88)
      ..cubicTo(
        size.width * 0.60,
        size.height * 0.72,
        size.width * 0.76,
        size.height * 0.79,
        size.width * 0.86,
        size.height * 0.66,
      )
      ..lineTo(size.width * 0.92, size.height * 0.51)
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.55,
        size.width * 0.57,
        size.height * 0.57,
        size.width * 0.50,
        size.height * 0.82,
      )
      ..close();

    final leftGoldPage = Path()
      ..moveTo(size.width * 0.14, size.height * 0.50)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.64,
        size.width * 0.42,
        size.height * 0.57,
        size.width * 0.50,
        size.height * 0.78,
      )
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.58,
        size.width * 0.28,
        size.height * 0.52,
        size.width * 0.14,
        size.height * 0.38,
      )
      ..close();

    final rightGoldPage = Path()
      ..moveTo(size.width * 0.86, size.height * 0.50)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.52,
        size.width * 0.55,
        size.height * 0.58,
        size.width * 0.50,
        size.height * 0.78,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.57,
        size.width * 0.76,
        size.height * 0.64,
        size.width * 0.86,
        size.height * 0.38,
      )
      ..close();

    final outerFlame = Path()
      ..moveTo(size.width * 0.48, size.height * 0.63)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.46,
        size.width * 0.42,
        size.height * 0.30,
        size.width * 0.50,
        size.height * 0.10,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.23,
        size.width * 0.55,
        size.height * 0.35,
        size.width * 0.71,
        size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.77,
        size.height * 0.62,
        size.width * 0.67,
        size.height * 0.70,
        size.width * 0.53,
        size.height * 0.78,
      )
      ..close();

    final innerCutout = Path()
      ..moveTo(size.width * 0.50, size.height * 0.74)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.56,
        size.width * 0.48,
        size.height * 0.47,
        size.width * 0.50,
        size.height * 0.30,
      )
      ..cubicTo(
        size.width * 0.56,
        size.height * 0.47,
        size.width * 0.70,
        size.height * 0.55,
        size.width * 0.55,
        size.height * 0.74,
      )
      ..close();

    final innerFlame = Path()
      ..moveTo(size.width * 0.50, size.height * 0.70)
      ..cubicTo(
        size.width * 0.39,
        size.height * 0.55,
        size.width * 0.49,
        size.height * 0.49,
        size.width * 0.50,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.61,
        size.height * 0.54,
        size.width * 0.61,
        size.height * 0.62,
        size.width * 0.50,
        size.height * 0.70,
      )
      ..close();

    canvas.drawPath(leftGoldPage, goldPagePaint);
    canvas.drawPath(rightGoldPage, goldPagePaint);
    canvas.drawPath(leftLowerBook, lowerBookPaint);
    canvas.drawPath(rightLowerBook, lowerBookPaint);
    canvas.drawPath(outerFlame, flamePaint);
    canvas.drawPath(innerCutout, ivoryPaint);
    canvas.drawPath(innerFlame, innerFlamePaint);

    final centerLine = Path()
      ..moveTo(size.width * 0.50, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.68,
        size.width * 0.50,
        size.height * 0.55,
      );
    canvas.drawPath(
      centerLine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.022
        ..strokeCap = StrokeCap.round
        ..color = AppColors.gold.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
