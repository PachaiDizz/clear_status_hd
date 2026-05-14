import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/whatsapp_verify_service.dart';
import '../utils/app_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WhatsAppVerifyService.markVerified();
      Get.offNamed('/home');
    }
  }

  void _openWhatsApp() {
    WhatsAppVerifyService.openTestChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Body ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),

                    // Icon ring
                    _buildIconRing(),

                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      'One-time setup',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Send a quick message so we can deliver\nyour HD media straight to you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.45),
                        height: 1.65,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Steps card
                    _buildStepsCard(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA ────────────────────────────────────
            _buildBottomCta(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  Widget _buildIconRing() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.18),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor.withOpacity(0.08),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.12),
            ),
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: AppTheme.primaryColor,
            size: 30,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  Widget _buildStepsCard() {
    final steps = [
      (
        'Tap Verify Now below',
        'WhatsApp opens with a pre-filled message ready to send.',
      ),
      (
        'Hit send',
        'Just tap the send button — takes 2 seconds.',
      ),
      (
        'Come back here',
        'The app detects you automatically and you\'re in.',
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isLast = i == steps.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number pill
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.$1,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.$2,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.42),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 0,
                  thickness: 0.5,
                  color: Colors.white.withOpacity(0.06),
                  indent: 58,
                  endIndent: 20,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderSubtle),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Verify button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.chat_rounded, size: 20),
              label: const Text('Verify Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Verification expires after 1 hour',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.25),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
