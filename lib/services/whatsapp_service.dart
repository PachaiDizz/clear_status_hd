import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// WhatsAppService
///
/// Handles all WhatsApp sharing via native MethodChannel on Android,
/// and system share sheet fallback on iOS.
///
/// All compressed outputs (video + photo-to-video) are .mp4,
/// so mimeType is always video/mp4 unless explicitly overridden.
class WhatsAppService {
  static const _channel =
      MethodChannel('com.example.purestatus_clone/whatsapp');

  // ── Config ────────────────────────────────────────────────
  // ⚠️ Move to a .env or constants file if repo is public
  static const String _myPhoneNumber = '601116266163';

  // ══════════════════════════════════════════════════════════
  // Share to myself (primary flow)
  // ══════════════════════════════════════════════════════════

  /// Sends a single compressed file directly to your own WhatsApp chat.
  /// This is the primary sharing method used after compression.
  static Future<void> shareToMyself(
    String filePath, {
    bool isVideo = true, // compressed output is always .mp4
  }) async {
    _assertFileExists(filePath);
    final mimeType = isVideo ? 'video/mp4' : 'image/jpeg';

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('shareToMyself', {
          'filePath': filePath,
          'mimeType': mimeType,
          'phone': _myPhoneNumber,
        });
      } on PlatformException catch (e) {
        throw Exception('Failed to share to WhatsApp: ${e.message}');
      }
    } else {
      // iOS: can't target a specific chat — fallback to share sheet
      await Share.shareXFiles([XFile(filePath)]);
    }
  }

  // ══════════════════════════════════════════════════════════
  // Share multiple parts (split video flow)
  // ══════════════════════════════════════════════════════════

  /// Sends multiple split video parts to your own WhatsApp chat,
  /// one by one with a delay to avoid overwhelming the intent stack.
  static Future<void> shareMultipleToMyself(
    List<String> filePaths, {
    bool isVideo = true,
  }) async {
    if (filePaths.isEmpty) return;

    if (Platform.isAndroid) {
      for (final path in filePaths) {
        await shareToMyself(path, isVideo: isVideo);
        // Small delay between shares — prevents Android intent stack issues
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } else {
      // iOS: share all parts at once via share sheet
      final files = filePaths.map((p) => XFile(p)).toList();
      await Share.shareXFiles(files);
    }
  }

  // ══════════════════════════════════════════════════════════
  // Share to generic WhatsApp (fallback / status flow)
  // ══════════════════════════════════════════════════════════

  /// Opens the WhatsApp share target (not a specific chat).
  /// Used for direct-to-status sharing without the bot.
  static Future<void> shareToWhatsApp(
    String filePath, {
    bool isVideo = true,
  }) async {
    _assertFileExists(filePath);
    final mimeType = isVideo ? 'video/mp4' : 'image/jpeg';

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('shareToWhatsApp', {
          'filePath': filePath,
          'mimeType': mimeType,
        });
      } on PlatformException catch (e) {
        throw Exception('Failed to share to WhatsApp: ${e.message}');
      }
    } else {
      await Share.shareXFiles([XFile(filePath)]);
    }
  }

  // ══════════════════════════════════════════════════════════
  // Check installation
  // ══════════════════════════════════════════════════════════

  /// Returns true if WhatsApp is installed on the device.
  /// Always returns true on iOS (handled by system share sheet).
  static Future<bool> isWhatsAppInstalled() async {
    if (Platform.isIOS) return true;
    try {
      return await _channel.invokeMethod<bool>('isWhatsAppInstalled') ?? false;
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // Private helpers
  // ══════════════════════════════════════════════════════════

  /// Throws early with a clear message if the file doesn't exist,
  /// instead of letting the native channel crash silently.
  static void _assertFileExists(String filePath) {
    if (!File(filePath).existsSync()) {
      debugPrint('❌ File not found: $filePath');
      throw Exception('Share failed: file not found at $filePath');
    }
  }
}
