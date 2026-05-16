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
  static const _sessionKey = 'verification_session_id';

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

  static Future<void> openTestChat() async {
    final encoded = Uri.encodeComponent(_verificationMessage);
    final uri = Uri.parse('https://wa.me/$_verificationNumber?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Fetch phone number from bot after verification
  static Future<String?> fetchPhoneFromBot() async {
    try {
      // Use device memory as session ID hint
      final sessionId = _storage.read<String>(_sessionKey) ?? '000000';

      debugPrint('🔍 Looking up phone for session: $sessionId');

      final response = await http
          .get(
            Uri.parse('$_botUrl/phone/$sessionId'),
          )
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
      debugPrint('⚠️ Phone not found in bot');
    } catch (e) {
      debugPrint('❌ Phone lookup error: $e');
    }
    return null;
  }

  /// Generate and save a session ID
  static void generateSessionId() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final sessionId = id.substring(id.length - 6);
    _storage.write(_sessionKey, sessionId);
    debugPrint('🆔 Session ID: $sessionId');
  }
}
