import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsAppVerifyService
///
/// Manages one-time WhatsApp verification via Twilio sandbox.
/// Verification is valid for 1 hour.
class WhatsAppVerifyService {
  // ── Twilio Sandbox Config ─────────────────────────────────
  static const String _verificationNumber = '14155238886';
  static const String _verificationMessage =
      'join nodded-higher'; // Update with your Twilio join code

  static const Duration _verificationWindow = Duration(hours: 1);

  // ── Storage ───────────────────────────────────────────────
  static final _storage = GetStorage();
  static const _key = 'whatsapp_verified_at';

  static bool isVerified() {
    try {
      final verifiedAt = _storage.read<String>(_key);
      if (verifiedAt == null) return false;

      final verifiedTime = DateTime.parse(verifiedAt);
      final elapsed = DateTime.now().difference(verifiedTime);

      if (elapsed >= _verificationWindow) {
        _storage.remove(_key);
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('⚠️ Verification read error: $e');
      _storage.remove(_key);
      return false;
    }
  }

  static void markVerified() {
    _storage.write(_key, DateTime.now().toIso8601String());
    debugPrint('✅ WhatsApp verified at ${DateTime.now()}');
  }

  static void clearVerification() {
    _storage.remove(_key);
    debugPrint('🔒 Verification cleared');
  }

  static String getTimeRemaining() {
    try {
      final verifiedAt = _storage.read<String>(_key);
      if (verifiedAt == null) return 'Not verified';

      final verifiedTime = DateTime.parse(verifiedAt);
      final remaining =
          _verificationWindow - DateTime.now().difference(verifiedTime);

      if (remaining.isNegative) return 'Expired';

      final minutes = remaining.inMinutes;
      return minutes > 0 ? '$minutes min remaining' : 'Expiring soon';
    } catch (_) {
      return 'Not verified';
    }
  }

  static Future<void> openTestChat() async {
    final encoded = Uri.encodeComponent(_verificationMessage);
    final uri = Uri.parse('https://wa.me/$_verificationNumber?text=$encoded');

    try {
      final canOpen = await canLaunchUrl(uri);
      if (!canOpen) {
        throw Exception(
            'WhatsApp is not installed or cannot be opened on this device.');
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('❌ Could not open WhatsApp: $e');
      rethrow;
    }
  }
}
