import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:moon_guard_flutter/theme/app_colors.dart';

class FamilyIllustration extends StatefulWidget {
  final double width;
  final double height;
  final double scale;
  const FamilyIllustration({super.key, this.width = 240, this.height = 200, this.scale = 1});

  @override
  State<FamilyIllustration> createState() => _FamilyIllustrationState();
}

class _FamilyIllustrationState extends State<FamilyIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  late final AnimationController _heart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    _ring.dispose();
    _float.dispose();
    _heart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: widget.scale,
      child: SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // pulsing protective glow
          AnimatedBuilder(
            animation: _glow,
            builder: (_, __) => Container(
              width: 224,
              height: 224,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05 + 0.13 * _glow.value),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),
          // dashed rotating ring
          AnimatedBuilder(
            animation: _ring,
            builder: (_, __) => Transform.rotate(
              angle: _ring.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(220, 220),
                painter: _DashedRingPainter(),
              ),
            ),
          ),
          // family svg (custom paint), with float
          AnimatedBuilder(
            animation: _float,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -4 * _float.value),
              child: CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _FamilyPainter(heartScale: 1 + 0.15 * _heart.value),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashWidth = 3.0;
    const dashSpace = 9.0;
    final radius = size.width / 2 - 4;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    for (var i = 0; i < dashCount; i++) {
      final start = (i * (dashWidth + dashSpace)) / radius;
      final end = start + dashWidth / radius;
      final path = Path()
        ..addArc(Rect.fromCircle(center: center, radius: radius), start, end - start);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FamilyPainter extends CustomPainter {
  final double heartScale;
  _FamilyPainter({required this.heartScale});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 240;
    final scaleY = size.height / 200;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(120, 180), width: 160, height: 16),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // DAD
    _drawPerson(
      canvas,
      headCenter: const Offset(68, 58),
      headRadius: 16,
      skin: const Color(0xFFD9A77A),
      hair: const Color(0xFF3A2A24),
      bodyGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7A1417), Color(0xFF3D0A0C)],
      ),
      bodyPath: Path()
        ..moveTo(44, 78)
        ..quadraticBezierTo(68, 70, 92, 78)
        ..lineTo(96, 130)
        ..quadraticBezierTo(68, 138, 40, 130)
        ..close(),
      legColor: const Color(0xFF1F1A18),
      legX1: 50,
      legX2: 72,
      legY: 130,
      legHeight: 40,
    );

    // MOM
    _drawPerson(
      canvas,
      headCenter: const Offset(172, 58),
      headRadius: 16,
      skin: const Color(0xFFE8B89A),
      hair: const Color(0xFF2A1815),
      hairLong: true,
      bodyGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8806B), Color(0xFFA41E22)],
      ),
      bodyPath: Path()
        ..moveTo(148, 78)
        ..quadraticBezierTo(172, 70, 196, 78)
        ..lineTo(204, 138)
        ..quadraticBezierTo(172, 144, 140, 138)
        ..close(),
      legColor: const Color(0xFFE8B89A),
      legX1: 156,
      legX2: 174,
      legY: 138,
      legHeight: 32,
    );

    // CHILD
    canvas.drawCircle(const Offset(120, 98), 12, Paint()..color = const Color(0xFFF2C7BD));
    final kidHair = Path()
      ..moveTo(108, 92)
      ..quadraticBezierTo(120, 82, 132, 92)
      ..lineTo(132, 100)
      ..quadraticBezierTo(120, 94, 108, 100)
      ..close();
    canvas.drawPath(kidHair, Paint()..color = const Color(0xFF5C3A2E));
    final kidBody = Path()
      ..moveTo(106, 114)
      ..quadraticBezierTo(120, 108, 134, 114)
      ..lineTo(138, 152)
      ..quadraticBezierTo(120, 158, 102, 152)
      ..close();
    canvas.drawPath(
      kidBody,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFC9C5), Color(0xFFE89B95)],
        ).createShader(const Rect.fromLTWH(102, 108, 36, 50)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(110, 152, 9, 22),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF3A2A24),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(121, 152, 9, 22),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF3A2A24),
    );

    // floating heart between parents
    canvas.save();
    canvas.translate(120, 84);
    canvas.scale(heartScale, heartScale);
    canvas.translate(-120, -84);
    final heart = Path()
      ..moveTo(120, 78)
      ..cubicTo(116, 70, 106, 70, 106, 80)
      ..cubicTo(106, 90, 120, 96, 120, 96)
      ..cubicTo(120, 96, 134, 90, 134, 80)
      ..cubicTo(134, 70, 124, 70, 120, 78)
      ..close();
    canvas.drawPath(heart, Paint()..color = AppColors.primary);
    canvas.restore();

    // shield emblem above family
    final shield = Path()
      ..moveTo(120, 18)
      ..cubicTo(128, 18, 134, 20, 138, 22)
      ..lineTo(138, 38)
      ..cubicTo(138, 48, 130, 54, 120, 58)
      ..cubicTo(110, 54, 102, 48, 102, 38)
      ..lineTo(102, 22)
      ..cubicTo(106, 20, 112, 18, 120, 18)
      ..close();
    canvas.drawPath(shield, Paint()..color = AppColors.primary);
    final check = Path()
      ..moveTo(114, 32)
      ..lineTo(118, 36)
      ..lineTo(126, 28);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  void _drawPerson(
    Canvas canvas, {
    required Offset headCenter,
    required double headRadius,
    required Color skin,
    required Color hair,
    bool hairLong = false,
    required LinearGradient bodyGradient,
    required Path bodyPath,
    required Color legColor,
    required double legX1,
    required double legX2,
    required double legY,
    required double legHeight,
  }) {
    canvas.drawCircle(headCenter, headRadius, Paint()..color = skin);
    if (hairLong) {
      final p = Path()
        ..moveTo(headCenter.dx - 16, headCenter.dy - 8)
        ..quadraticBezierTo(headCenter.dx, headCenter.dy - 22, headCenter.dx + 16, headCenter.dy - 8)
        ..lineTo(headCenter.dx + 20, headCenter.dy + 22)
        ..quadraticBezierTo(headCenter.dx, headCenter.dy + 12, headCenter.dx - 20, headCenter.dy + 22)
        ..close();
      canvas.drawPath(p, Paint()..color = hair);
    } else {
      final p = Path()
        ..moveTo(headCenter.dx - 16, headCenter.dy - 8)
        ..quadraticBezierTo(headCenter.dx, headCenter.dy - 20, headCenter.dx + 16, headCenter.dy - 8)
        ..lineTo(headCenter.dx + 16, headCenter.dy)
        ..quadraticBezierTo(headCenter.dx, headCenter.dy - 6, headCenter.dx - 16, headCenter.dy)
        ..close();
      canvas.drawPath(p, Paint()..color = hair);
    }
    canvas.drawPath(
      bodyPath,
      Paint()..shader = bodyGradient.createShader(bodyPath.getBounds()),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(legX1, legY, 14, legHeight),
        const Radius.circular(4),
      ),
      Paint()..color = legColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(legX2, legY, 14, legHeight),
        const Radius.circular(4),
      ),
      Paint()..color = legColor,
    );
  }

  @override
  bool shouldRepaint(covariant _FamilyPainter oldDelegate) =>
      oldDelegate.heartScale != heartScale;
}
