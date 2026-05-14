import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/whatsapp_verify_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _typeController;
  late Animation<double> _iconAnim;

  final String _creditText = 'Created by PachaiDizz';
  String _displayedText = '';
  int _typeIndex = 0;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _typeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _creditText.length * 60),
    );

    _iconAnim = CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOut,
    );

    _iconController.forward();

    _iconController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 200), _startTypeWriter);
      }
    });

    Future.delayed(const Duration(seconds: 4), _navigate);
  }

  void _startTypeWriter() {
    Future.doWhile(() async {
      if (_typeIndex >= _creditText.length) return false;
      if (!mounted) return false;
      await Future.delayed(const Duration(milliseconds: 60));
      setState(() {
        _displayedText += _creditText[_typeIndex];
        _typeIndex++;
      });
      return true;
    });
  }

  void _navigate() {
    if (WhatsAppVerifyService.isVerified()) {
      Get.offNamed('/home');
    } else {
      Get.offNamed('/setup');
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F2D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            AnimatedBuilder(
              animation: _iconAnim,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(140, 140),
                  painter: _IconPainter(_iconAnim.value),
                );
              },
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _iconAnim,
              builder: (context, _) {
                return Opacity(
                  opacity: (_iconAnim.value * 2).clamp(0.0, 1.0),
                  child: const Text(
                    'STATUS HD',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 24,
              child: Text(
                _displayedText,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5ECFB8),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Spacer(),
            _BouncingDots(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final double progress;
  _IconPainter(this.progress);

  double easeOut(double t) => 1 - pow(1 - t, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;
    final cx = W / 2;
    final cy = H / 2;

    final p1 = (progress * 2).clamp(0.0, 1.0);
    final p2 = ((progress - 0.3) * 2).clamp(0.0, 1.0);
    final p3 = ((progress - 0.6) * 2.5).clamp(0.0, 1.0);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A9E8F).withValues(alpha: easeOut(p1)),
          Color(0xFF0D6E8A).withValues(alpha: easeOut(p1)),
        ],
      ).createShader(Rect.fromLTWH(0, 0, W, H));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, W, H),
        const Radius.circular(28),
      ),
      bgPaint,
    );

    if (p2 > 0) {
      final circlePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15 * easeOut(p2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: 46),
        -pi / 2,
        2 * pi * p2,
        false,
        circlePaint,
      );
    }

    if (p3 > 0) {
      final alpha = easeOut(p3);
      final slideY = 10 * (1 - easeOut(p3));

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'HD',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - 34 + slideY),
      );

      final barAlpha = ((p3 - 0.3) / 0.7).clamp(0.0, 1.0);
      if (barAlpha > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(W * 0.2, cy + 28, W * 0.6 * easeOut(barAlpha), 3),
            const Radius.circular(2),
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35 * easeOut(barAlpha)),
        );
      }

      final statusAlpha = ((p3 - 0.5) / 0.5).clamp(0.0, 1.0);
      if (statusAlpha > 0) {
        final statusPainter = TextPainter(
          text: TextSpan(
            text: 'STATUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6 * easeOut(statusAlpha)),
              letterSpacing: 3,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        statusPainter.layout();
        statusPainter.paint(
          canvas,
          Offset(cx - statusPainter.width / 2, cy + 38),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.progress != progress;
}

class _BouncingDots extends StatefulWidget {
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final offset = ((_controller.value * 3) - i).clamp(0.0, 1.0);
            final opacity = sin(offset * pi).clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Color(0xFF1A9E8F).withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
