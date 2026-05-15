import 'dart:io';
import 'package:share_plus/share_plus.dart';

/// ShareService
///
/// Handles sharing compressed media to WhatsApp Status.
///
/// On Android: uses Intent with WhatsApp package name to open directly in WA.
/// On iOS: uses system share sheet — user selects WhatsApp from the sheet.
class ShareService {
  /// Share a single file to WhatsApp Status
  static Future<void> shareToWhatsApp(String filePath) async {
    final file = XFile(filePath);

    if (Platform.isAndroid) {
      // On Android, we can target WhatsApp directly
      await Share.shareXFiles(
        [file],
        text: '',
      );
      // Note: To directly open WhatsApp status on Android,
      // use the android_intent_plus package:
      // final intent = AndroidIntent(
      //   action: 'action_send',
      //   package: 'com.whatsapp',
      //   type: filePath.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg',
      //   flags: [Flag.FLAG_GRANT_READ_URI_PERMISSION],
      //   arguments: {'android.intent.extra.STREAM': filePath},
      // );
      // await intent.launch();
    } else {
      // iOS: system share sheet
      await Share.shareXFiles([file]);
    }
  }

  /// Share multiple files (split video parts) to WhatsApp
  static Future<void> shareMultipleToWhatsApp(List<String> filePaths) async {
    final files = filePaths.map((path) => XFile(path)).toList();

    await Share.shareXFiles(
      files,
      text: 'Shared via HD Status',
    );
  }

  /// Check if WhatsApp is installed (Android only)
  /// Returns true on iOS always (we use system share sheet)
  static Future<bool> isWhatsAppInstalled() async {
    if (Platform.isIOS) return true;

    // On Android, you can use device_apps package to check
    // For now, we return true and let the share sheet handle it
    return true;
  }
}
