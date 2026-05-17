import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class WhatsAppVerifyService {
  static const String _verificationNumber = '14155238886';
  static const Duration _verificationWindow = Duration(hours: 1);
  static const String _botUrl = 'https://whatsapp-bot-9vw8.onrender.com';

  static final _storage = GetStorage();
  static const _verifyKey = 'whatsapp_verified_at';
  static const _phoneKey = 'user_phone_number';
  static const _timestampKey = 'verify_tap_timestamp';
  static const _joinIndexKey = 'join_code_index';

  // All join codes — rotated per user across 4 Twilio accounts
  static const List<String> _joinCodes = [
    'join nodded-higher',
    'join saddle-drop',
    'join machine-flew',
    'join active-any',
  ];

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

  // ── Step 1: Join Sandbox (rotated code) ──────────────────
  static String _getJoinCode() {
    final lastIndex = _storage.read<int>(_joinIndexKey) ?? -1;
    final nextIndex = (lastIndex + 1) % _joinCodes.length;
    _storage.write(_joinIndexKey, nextIndex);
    return _joinCodes[nextIndex];
  }

  static Future<void> openJoinChat() async {
    final joinCode = _getJoinCode();
    debugPrint('📲 Step 1: Using join code: $joinCode');

    final encoded = Uri.encodeComponent(joinCode);
    final uri = Uri.parse('https://wa.me/$_verificationNumber?text=$encoded');
    debugPrint('📲 Step 1: Opening WhatsApp to join sandbox');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Step 2: Verify Number ─────────────────────────────────
  static Future<void> openVerifyChat() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _storage.write(_timestampKey, timestamp);
    debugPrint('⏱️ Step 2: Verify tapped at $timestamp');

    const message = 'This is My Verification Message';
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$_verificationNumber?text=$encoded');
    debugPrint('📲 Step 2: Opening WhatsApp to verify number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Bot polling ───────────────────────────────────────────
  static Future<String?> fetchPhoneFromBot() async {
    try {
      final timestamp = _storage.read<int>(_timestampKey);
      if (timestamp == null) {
        debugPrint('⚠️ No timestamp — complete Step 2 first');
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
      debugPrint('⚠️ No phone found yet');
    } catch (e) {
      debugPrint('❌ Phone lookup error: $e');
    }
    return null;
  }

  // ── Kept for compatibility ────────────────────────────────
  static void generateSessionId() {
    debugPrint('🆔 Session ready (timestamp-based)');
  }
}
