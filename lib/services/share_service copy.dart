import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_apps/device_apps.dart';
import 'package:share_plus/share_plus.dart';

/// ShareService
///
/// Handles sharing compressed media to WhatsApp.
///
/// On Android: uses AndroidIntent to open WhatsApp directly (no share sheet).
/// On iOS: uses system share sheet — user selects WhatsApp from the sheet.
class ShareService {
  static const _whatsappPackage = 'com.whatsapp';

  // ══════════════════════════════════════════════════════════
  // Share single file
  // ══════════════════════════════════════════════════════════

  /// Share a single compressed file directly to WhatsApp.
  static Future<void> shareToWhatsApp(String filePath) async {
    try {
      if (Platform.isAndroid) {
        await _shareAndroid(filePath);
      } else {
        // iOS: system share sheet
        await Share.shareXFiles([XFile(filePath)]);
      }
    } catch (e) {
      throw Exception('Share failed: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // Share multiple files (split video parts)
  // ══════════════════════════════════════════════════════════

  /// Share multiple split video parts to WhatsApp.
  /// On Android, shares them one by one directly to WhatsApp.
  /// On iOS, uses the system share sheet for all files at once.
  static Future<void> shareMultipleToWhatsApp(List<String> filePaths) async {
    if (filePaths.isEmpty) return;

    try {
      if (Platform.isAndroid) {
        // Share each part individually so WhatsApp receives them cleanly
        for (final path in filePaths) {
          await _shareAndroid(path);
          // Small delay between shares to avoid overwhelming the intent stack
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } else {
        // iOS: all files at once via share sheet
        final files = filePaths.map((path) => XFile(path)).toList();
        await Share.shareXFiles(files);
      }
    } catch (e) {
      throw Exception('Share failed: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // Check if WhatsApp is installed
  // ══════════════════════════════════════════════════════════

  /// Returns true if WhatsApp is installed.
  /// Always returns true on iOS (handled by system share sheet).
  static Future<bool> isWhatsAppInstalled() async {
    if (Platform.isIOS) return true;
    try {
      return await DeviceApps.isAppInstalled(_whatsappPackage);
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // Private: Android direct intent
  // ══════════════════════════════════════════════════════════

  static Future<void> _shareAndroid(String filePath) async {
    final mimeType = filePath.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg';

    final intent = AndroidIntent(
      action: 'android.intent.action.SEND',
      package: _whatsappPackage,
      type: mimeType,
      flags: [Flag.FLAG_GRANT_READ_URI_PERMISSION],
      arguments: {'android.intent.extra.STREAM': filePath},
    );

    await intent.launch();
  }
}
