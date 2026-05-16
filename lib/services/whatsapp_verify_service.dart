import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class WhatsAppVerifyService {
  static const String _verificationNumber = '14155238886';
  static const String _verificationMessage = 'join nodded-higher';
  static const Duration _verificationWindow = Duration(hours: 1);
  static const String _botUrl = 'https://whatsapp-bot-9vw8.onrender.com';

  static final _storage = GetStorage();
  static const _verifyKey = 'whatsapp_verified_at';
  static const _phoneKey = 'user_phone_number';
  static const _timestampKey = 'verify_tap_timestamp';

  // ── Verification state ────────────────────────────────────

  static bool isVerified() {
    try {
      final verifiedAt = _storage.read<String>(_verifyKey);
      if (verifiedAt == null) return false;
      final verifiedTime = DateTime.parse(verifiedAt);
      if (DateTime.now().difference(verifiedTime) >= _verificationWindow) {
        _storage.remove(_verifyKey);
        return false;
      }
      return true;
    } catch (_) {
      _storage.remove(_verifyKey);
      return false;
    }
  }

  static void markVerified() {
    _storage.write(_verifyKey, DateTime.now().toIso8601String());
  }

  static void clearVerification() {
    _storage.remove(_verifyKey);
  }

  static String getTimeRemaining() {
    try {
      final verifiedAt = _storage.read<String>(_verifyKey);
      if (verifiedAt == null) return 'Not verified';
      final remaining = _verificationWindow -
          DateTime.now().difference(DateTime.parse(verifiedAt));
      if (remaining.isNegative) return 'Expired';
      return '${remaining.inMinutes} min';
    } catch (_) {
      return 'Unknown';
    }
  }

  // ── Phone number ──────────────────────────────────────────

  static void setPhoneNumber(String phone) {
    _storage.write(_phoneKey, phone.replaceAll(RegExp(r'[+\s]'), ''));
  }

  static String getPhoneNumber() {
    return _storage.read<String>(_phoneKey) ?? '';
  }

  static bool hasPhoneNumber() {
    final phone = _storage.read<String>(_phoneKey);
    return phone != null && phone.isNotEmpty;
  }

  // ── Session (kept for compatibility, no longer used for lookup) ──

  static void generateSessionId() {
    // No longer needed — timestamp-based detection handles everything
    debugPrint('🆔 Session ready (timestamp-based)');
  }

  // ── WhatsApp ──────────────────────────────────────────────

  /// Opens WhatsApp with "join nodded-higher"
  /// Records the exact timestamp so we can match the user's phone later
  static Future<void> openTestChat() async {
    // Save timestamp of when user tapped Verify Now
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _storage.write(_timestampKey, timestamp);
    debugPrint('⏱️ Verify tapped at: $timestamp');

    final encoded = Uri.encodeComponent(_verificationMessage);
    final uri = Uri.parse('https://wa.me/$_verificationNumber?text=$encoded');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Bot polling ───────────────────────────────────────────

  /// Called when app resumes after user sends WhatsApp message.
  /// Asks the bot for the phone number closest to our saved timestamp.
  static Future<String?> fetchPhoneFromBot() async {
    try {
      final timestamp = _storage.read<int>(_timestampKey);
      if (timestamp == null) {
        debugPrint('⚠️ No timestamp saved — tap Verify Now first');
        return null;
      }

      debugPrint('🔍 Looking up phone for timestamp: $timestamp');

      final response = await http
          .get(Uri.parse('$_botUrl/phone-by-time/$timestamp'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final phone = data['phone']?.toString() ?? '';
        if (phone.isNotEmpty && phone.length >= 8) {
          debugPrint('📱 Phone detected: $phone');
          setPhoneNumber(phone);
          return phone;
        }
      }
      debugPrint('⚠️ No phone found for this timestamp yet');
    } catch (e) {
      debugPrint('❌ Phone lookup error: $e');
    }
    return null;
  }
}
