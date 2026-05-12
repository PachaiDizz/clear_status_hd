import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseUploadService {
  static const String myPhoneNumber = '601116266163';

  // Twilio sandbox URL — your Render bot
  static const String botUrl = 'https://whatsapp-bot-9vw8.onrender.com';

  Future<String> uploadVideo(String filePath,
      {void Function(double)? onProgress}) async {
    try {
      print('🔍 Uploading file...');
      print('🔍 File exists: ${File(filePath).existsSync()}');
      print('🔍 File size: ${File(filePath).lengthSync()} bytes');

      // Send directly to the bot
      final request =
          http.MultipartRequest('POST', Uri.parse('$botUrl/upload'));
      request.fields['phone'] = myPhoneNumber;
      request.files.add(await http.MultipartFile.fromPath('video', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🔍 Bot response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return 'sent';
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }
}
