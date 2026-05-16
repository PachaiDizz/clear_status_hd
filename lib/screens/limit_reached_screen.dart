import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class LimitReachedScreen extends StatelessWidget {
  const LimitReachedScreen({super.key});

  Future<void> _contactDeveloper() async {
    final url = Uri.parse(
        'https://wa.me/601116266163?text=Hi%2C%20I%20want%20to%20upgrade%20HD%20Status');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  'Trial Ended',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You\'ve used all 3 free HD uploads.\n\nThanks for trying Status HD! 🎉\n\nTo continue using the app, please contact\nthe developer for full access.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16, color: Colors.white70, height: 1.6),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _contactDeveloper,
                  icon: const Icon(Icons.chat),
                  label: const Text('Contact Developer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
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
