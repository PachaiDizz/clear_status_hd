import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class WhatsAppService {
  static const _channel =
      MethodChannel('com.example.purestatus_clone/whatsapp');

  /// Share a file directly to WhatsApp using FileProvider (Android)
  /// or share_plus fallback (iOS).
  ///
  /// This is the same technique Pure Status uses:
  /// FileProvider + ACTION_SEND to com.whatsapp
  /// → WhatsApp treats it as received media → no recompression → HD quality!
  static Future<void> shareToWhatsApp(
    String filePath, {
    bool isVideo = false,
  }) async {
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
      // iOS — use share_plus (best available on iOS sandbox)
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Status HD',
      );
    }
  }

  /// Share multiple files to WhatsApp (for split videos)
  static Future<void> shareMultipleToWhatsApp(
    List<String> filePaths, {
    bool isVideo = false,
  }) async {
    if (Platform.isAndroid) {
      // Share one by one — WhatsApp handles them sequentially
      for (final path in filePaths) {
        await shareToWhatsApp(path, isVideo: isVideo);
        // Small delay between shares
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } else {
      // iOS — share all at once
      await Share.shareXFiles(
        filePaths.map((p) => XFile(p)).toList(),
        subject: 'Status HD',
      );
    }
  }

  /// Check if WhatsApp is installed (Android only)
  static Future<bool> isWhatsAppInstalled() async {
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>('isWhatsAppInstalled');
        return result ?? false;
      } catch (_) {
        return false;
      }
    }
    return true; // Assume installed on iOS
  }
}
