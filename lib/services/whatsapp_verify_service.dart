import 'dart:convert';
import 'dart:math';
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
  static const _sessionKey = 'verification_session_id';

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

  // ── Session ID ────────────────────────────────────────────

  /// Generates a new random 6-character alphanumeric session ID.
  /// Called once when the setup screen opens.
  static void generateSessionId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    final sessionId =
        List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    _storage.write(_sessionKey, sessionId);
    debugPrint('🆔 Session ID: $sessionId');
  }

  static String getSessionId() {
    return _storage.read<String>(_sessionKey) ?? '';
  }

  // ── WhatsApp ──────────────────────────────────────────────

  /// Opens WhatsApp with "verify <sessionId>" as the pre-filled message.
  /// The bot webhook reads this to link the session to the user's phone.
  static Future<void> openTestChat() async {
    final sessionId = getSessionId();
    if (sessionId.isEmpty) {
      debugPrint('⚠️ No session ID — call generateSessionId() first');
      return;
    }

    final message = 'verify $sessionId';
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$_verificationNumber?text=$encoded');
    debugPrint('📲 Opening WhatsApp with: $message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Bot polling ───────────────────────────────────────────

  /// Polls the bot for the phone number linked to this session ID.
  /// Returns the phone string on success, null if not found yet.
  static Future<String?> fetchPhoneFromBot() async {
    try {
      final sessionId = getSessionId();
      if (sessionId.isEmpty) {
        debugPrint('⚠️ No session ID to look up');
        return null;
      }

      debugPrint('🔍 Looking up session: $sessionId');

      final response = await http
          .get(Uri.parse('$_botUrl/phone/$sessionId'))
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
      debugPrint('⚠️ No phone found for session $sessionId');
    } catch (e) {
      debugPrint('❌ Phone lookup error: $e');
    }
    return null;
  }
}
