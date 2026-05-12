// whatsapp_service.dart – updated version

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class WhatsAppService {
  static const _channel =
      MethodChannel('com.example.purestatus_clone/whatsapp');

  // 🔹 Set your own phone number here (full international format, no '+' or spaces)
  static const String myPhoneNumber = '601116266163'; // <-- CHANGE THIS

  /// Existing method – share to generic WhatsApp (opens share sheet)
  static Future<void> shareToWhatsApp(String filePath,
      {bool isVideo = false}) async {
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
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Status HD',
      );
    }
  }

  /// ✨ NEW: Send the file directly to your own WhatsApp chat
  static Future<void> shareToMyself(String filePath,
      {bool isVideo = false}) async {
    final mimeType = isVideo ? 'video/mp4' : 'image/jpeg';

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('shareToMyself', {
          'filePath': filePath,
          'mimeType': mimeType,
          'phone': myPhoneNumber, // passed to native
        });
      } on PlatformException catch (e) {
        throw Exception('Failed to share to myself: ${e.message}');
      }
    } else {
      // iOS can't target a specific chat – fallback to share sheet
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Status HD',
      );
    }
  }

  /// Share multiple files (existing)
  ///
  static Future<void> shareMultipleToWhatsApp(
    List<String> filePaths, {
    bool isVideo = false,
  }) async {
    if (Platform.isAndroid) {
      for (final path in filePaths) {
        await shareToWhatsApp(path, isVideo: isVideo);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } else {
      await Share.shareXFiles(
        filePaths.map((p) => XFile(p)).toList(),
        subject: 'Status HD',
      );
    }
  }

  static Future<void> shareMultipleToMyself(
    List<String> filePaths, {
    bool isVideo = false,
  }) async {
    if (Platform.isAndroid) {
      for (final path in filePaths) {
        await shareToMyself(path, isVideo: isVideo);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } else {
      await Share.shareXFiles(
        filePaths.map((p) => XFile(p)).toList(),
        subject: 'Status HD',
      );
    }
  }

  /// Check if WhatsApp is installed (existing)
  static Future<bool> isWhatsAppInstalled() async {
    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<bool>('isWhatsAppInstalled') ??
            false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }
}
