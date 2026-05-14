import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/whatsapp_verify_service.dart';
import '../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final String _creditText = 'Created by PachaiDizz';
  String _displayedText = '';
  int _typeIndex = 0;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();

    // Start typewriter after logo fades in
    Future.delayed(const Duration(milliseconds: 800), _startTypeWriter);

    // Navigate after 4 s
    Future.delayed(const Duration(seconds: 4), _navigate);
  }

  void _startTypeWriter() {
    Future.doWhile(() async {
      if (_typeIndex >= _creditText.length) return false;
      if (!mounted) return false;
      await Future.delayed(const Duration(milliseconds: 55));
      setState(() {
        _displayedText += _creditText[_typeIndex];
        _typeIndex++;
      });
      return true;
    });
  }

  void _navigate() {
    if (!mounted) return;
    if (WhatsAppVerifyService.isVerified()) {
      Get.offNamed('/home');
    } else {
      Get.offNamed('/setup');
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo + title ──────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo box
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppTheme.logoBg,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'HD',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                              letterSpacing: -2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Status HD',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BY PACHAIDIZZ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.3),
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom: loader + credit ───────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Column(
                children: [
                  const _BouncingDots(),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 18,
                    child: Text(
                      _displayedText,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor.withOpacity(0.55),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
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

// ── Bouncing dots loader ──────────────────────────────────────
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final raw = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final opacity = sin(raw * pi).clamp(0.15, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
