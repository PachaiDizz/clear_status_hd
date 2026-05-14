import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/whatsapp_verify_service.dart';

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
      backgroundColor: const Color(0xFF075E54),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Verify WhatsApp',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'To receive HD videos, verification is required.\n\nTap the button, send the pre-filled message,\nthen return to this app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _openWhatsApp,
                  icon: const Icon(Icons.chat, size: 28),
                  label: const Text('Verify Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 18),
                    textStyle: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verification expires after 1 hour',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
