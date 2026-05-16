import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// UploadService
///
/// Uploads compressed media to the WhatsApp bot for HD delivery.
/// The bot receives the file and sends it to the detected phone number.
class UploadService {
  static const String _botUrl = 'https://whatsapp-bot-9vw8.onrender.com';
  static const Duration _uploadTimeout = Duration(seconds: 120);

  // Dynamic phone number (set after verification)
  static String _phoneNumber = '601116266163';

  /// Set the user's phone number (called after verification)
  static void setPhoneNumber(String phone) {
    _phoneNumber = phone.replaceAll(RegExp(r'[+\s]'), '');
  }

  /// Uploads [filePath] to the bot and triggers HD delivery.
  static Future<void> uploadVideo(
    String filePath, {
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      throw Exception('Upload failed: file not found at $filePath');
    }

    final fileSize = file.lengthSync();
    debugPrint('📤 Uploading: $filePath');
    debugPrint('📦 File size: ${(fileSize / 1048576).toStringAsFixed(2)} MB');

    try {
      final uri = Uri.parse('$_botUrl/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['phone'] = _phoneNumber;
      request.files.add(
        await http.MultipartFile.fromPath('video', filePath),
      );

      onProgress?.call(0.1);

      final streamedResponse = await request.send().timeout(
            _uploadTimeout,
            onTimeout: () => throw Exception(
              'Upload timed out after ${_uploadTimeout.inSeconds}s — '
              'check your connection or try again.',
            ),
          );

      onProgress?.call(0.8);

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('🤖 Bot response: ${response.statusCode} — ${response.body}');

      if (response.statusCode == 200) {
        onProgress?.call(1.0);
        debugPrint('✅ Upload successful — HD delivery triggered');
      } else {
        throw Exception(
          'Upload failed (${response.statusCode}): ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('No internet connection — please check your network.');
    } on Exception {
      rethrow;
    }
  }
}
