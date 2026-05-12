import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// FirebaseUploadService
///
/// Uploads compressed video to Firebase Storage
/// and stores metadata in Firestore.
/// The bot will detect new uploads and send them to your WhatsApp.
class FirebaseUploadService {
  static const _uuid = Uuid();
  static const String myPhoneNumber = '601116266163'; // Your number

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload a video file and trigger bot delivery
  Future<String> uploadVideo(String filePath,
      {void Function(double)? onProgress}) async {
    try {
      print('🔍 Starting upload...');
      print('🔍 File path: $filePath');
      print('🔍 File exists: ${File(filePath).existsSync()}');

      final fileName = '${_uuid.v4()}.mp4';
      final ref = _storage.ref().child('videos/$fileName');

      print('🔍 Uploading to: videos/$fileName');

      final uploadTask = ref.putFile(File(filePath));

      uploadTask.snapshotEvents.listen((snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      final snapshot = await uploadTask;
      print('🔍 Upload done, getting URL...');

      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('🔍 Download URL: $downloadUrl');

      await _firestore.collection('uploads').add({
        'phone': myPhoneNumber,
        'url': downloadUrl,
        'type': 'video',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('🔍 Firestore document added!');
      return downloadUrl;
    } catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }
}
