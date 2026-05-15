import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsAppVerifyService
///
/// Manages one-time WhatsApp verification via a pre-filled chat link.
/// Verification is valid for [_verificationWindow] (default: 1 hour).
/// The timestamp is persisted via GetStorage so it survives app restarts.
class WhatsAppVerifyService {
  // ── Config ────────────────────────────────────────────────
  // ⚠️ Move to a constants file if repo is public
  static const String _verificationNumber = '15556490848';
  static const String _verificationMessage = 'HD Status Verification';

  // Single source of truth for the verification window
  static const Duration _verificationWindow = Duration(hours: 1);

  // ── Storage ───────────────────────────────────────────────
  static final _storage = GetStorage();
  static const _key = 'whatsapp_verified_at';

  // ══════════════════════════════════════════════════════════
  // Check verification status
  // ══════════════════════════════════════════════════════════

  /// Returns true if the user has verified within the last hour.
  static bool isVerified() {
    try {
      final verifiedAt = _storage.read<String>(_key);
      if (verifiedAt == null) return false;

      final verifiedTime = DateTime.parse(verifiedAt);
      final elapsed = DateTime.now().difference(verifiedTime);

      if (elapsed >= _verificationWindow) {
        _storage.remove(_key); // Clean up expired token
        return false;
      }

      return true;
    } catch (e) {
      // Stored value is corrupted — clear it and force re-verification
      debugPrint('⚠️ Verification read error: $e');
      _storage.remove(_key);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // Mark as verified
  // ══════════════════════════════════════════════════════════

  /// Saves the current timestamp as the verification time.
  /// Called when the user returns to the app after opening WhatsApp.
  static void markVerified() {
    _storage.write(_key, DateTime.now().toIso8601String());
    debugPrint('✅ WhatsApp verified at ${DateTime.now()}');
  }

  // ══════════════════════════════════════════════════════════
  // Clear verification
  // ══════════════════════════════════════════════════════════

  /// Manually clears verification — forces user to re-verify.
  static void clearVerification() {
    _storage.remove(_key);
    debugPrint('🔒 Verification cleared');
  }

  // ══════════════════════════════════════════════════════════
  // Time remaining
  // ══════════════════════════════════════════════════════════

  /// Returns a human-readable string of how long verification remains.
  /// e.g. "42 min remaining", "Expired", "Not verified"
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

  // ══════════════════════════════════════════════════════════
  // Open WhatsApp chat
  // ══════════════════════════════════════════════════════════

  /// Opens WhatsApp with a pre-filled verification message.
  /// Throws if WhatsApp is not installed or the URL cannot be launched.
  static Future<void> openTestChat() async {
    final encoded = Uri.encodeComponent(_verificationMessage);
    final uri = Uri.parse('https://wa.me/$_verificationNumber?text=$encoded');

    try {
      final canOpen = await canLaunchUrl(uri);
      if (!canOpen) {
        throw Exception(
          'WhatsApp is not installed or cannot be opened on this device.',
        );
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('❌ Could not open WhatsApp: $e');
      rethrow; // Let the UI (SetupScreen) show the error
    }
  }
}
