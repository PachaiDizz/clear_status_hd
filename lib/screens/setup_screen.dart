import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/whatsapp_verify_service.dart';
import '../services/upload_service.dart';
import '../utils/app_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _hasJoined = false; // tracks if user completed Step 1

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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Only detect phone after Step 2 (verify)
    if (state == AppLifecycleState.resumed && _hasJoined && !_isLoading) {
      setState(() => _isLoading = true);

      final phone = await WhatsAppVerifyService.fetchPhoneFromBot();

      if (phone != null && phone.isNotEmpty) {
        UploadService.setPhoneNumber(phone);
        WhatsAppVerifyService.markVerified();
        Get.offNamed('/home');
      } else {
        setState(() => _isLoading = false);
        Get.snackbar(
          'Not Detected',
          'Please make sure you sent the message in Step 2.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    }
  }

  void _onStep1Pressed() async {
    await WhatsAppVerifyService.openJoinChat();
    // Mark step 1 done so UI updates
    setState(() => _hasJoined = true);
  }

  void _onStep2Pressed() async {
    await WhatsAppVerifyService.openVerifyChat();
    // App will detect resume and fetch phone automatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),
                    _buildIconRing(),
                    const SizedBox(height: 28),
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
                    Text(
                      'Two quick steps so we can deliver\nyour HD media straight to you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.45),
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildStepsCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildBottomCta(),
          ],
        ),
      ),
    );
  }

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

  Widget _buildStepsCard() {
    final steps = [
      (
        '1️⃣ Join the sandbox',
        'Tap "Step 1 - Join" below. WhatsApp opens — just hit send.',
        _hasJoined,
      ),
      (
        '2️⃣ Verify your number',
        'Tap "Step 2 - Verify" below. WhatsApp opens again — hit send.',
        false,
      ),
      (
        '3️⃣ Come back here',
        'The app detects your number automatically and you\'re in.',
        false,
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
          final isDone = step.$3;

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step number / checkmark
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.green.withOpacity(0.15)
                            : AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          isDone ? Icons.check : null,
                          size: 14,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.$1,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDone ? Colors.green : Colors.white,
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

  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          else ...[
            // Step 1 button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _hasJoined ? null : _onStep1Pressed,
                icon: Icon(
                  _hasJoined ? Icons.check_circle : Icons.chat_rounded,
                  size: 20,
                ),
                label: Text(_hasJoined ? 'Joined ✓' : 'Step 1 — Join Sandbox'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasJoined
                      ? Colors.green.withOpacity(0.2)
                      : AppTheme.primaryColor,
                  foregroundColor: _hasJoined ? Colors.green : Colors.black,
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
            const SizedBox(height: 12),
            // Step 2 button — only enabled after Step 1
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _hasJoined ? _onStep2Pressed : null,
                icon: const Icon(Icons.verified_rounded, size: 20),
                label: const Text('Step 2 — Verify My Number'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white.withOpacity(0.05),
                  disabledForegroundColor: Colors.white.withOpacity(0.2),
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
          ],
          const SizedBox(height: 14),
          Text(
            'Step 1 is one-time only. Step 2 verifies your number.',
            textAlign: TextAlign.center,
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
