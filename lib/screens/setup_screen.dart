import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/whatsapp_verify_service.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

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
                  'One-Time Setup',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'To enable HD video delivery, verification is required.\n\nThis verification is only needed once every hour.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => WhatsAppVerifyService.openTestChat(),
                  icon: const Icon(Icons.chat),
                  label: const Text('Open WhatsApp Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Send "Hello" and come back',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    WhatsAppVerifyService.markVerified();
                    Get.offNamed('/home');
                  },
                  child: const Text('I\'ve sent the message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF075E54),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
