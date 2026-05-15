import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/media_item.dart';
import '../services/compression_service.dart';
import '../services/upload_service.dart';
import '../services/whatsapp_service.dart';
import '../services/tips_service.dart';
import '../services/whatsapp_verify_service.dart';

class HomeController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  final RxList<MediaItem> mediaItems = <MediaItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt selectedTabIndex = 0.obs;

  Future<void> pickVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (file == null) return;

      final size = await File(file.path).length();
      final duration = await CompressionService.getVideoDuration(file.path);

      final item = MediaItem(
        id: _uuid.v4(),
        originalPath: file.path,
        type: MediaType.video,
        originalSizeBytes: size,
        duration: duration,
      );

      mediaItems.add(item);
    } catch (e) {
      Get.snackbar('Error', 'Could not pick video: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  Future<void> pickPhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (file == null) return;

      final size = await File(file.path).length();

      final item = MediaItem(
        id: _uuid.v4(),
        originalPath: file.path,
        type: MediaType.photo,
        originalSizeBytes: size,
      );

      mediaItems.add(item);
    } catch (e) {
      Get.snackbar('Error', 'Could not pick photo: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  Future<void> compressItem(String itemId) async {
    // Check verification
    if (!WhatsAppVerifyService.isVerified()) {
      Get.snackbar(
        'Verification Required',
        'Please send a message to the delivery number first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      Get.offNamed('/setup');
      return;
    }

    final index = mediaItems.indexWhere((m) => m.id == itemId);

    try {
      String outputPath;

      if (mediaItems[index].isVideo) {
        outputPath = await CompressionService.compressVideo(
          mediaItems[index].originalPath,
          onProgress: (progress) {
            final idx = mediaItems.indexWhere((m) => m.id == itemId);
            if (idx != -1) {
              mediaItems[idx] = mediaItems[idx].copyWith(
                compressionProgress: progress,
              );
              mediaItems.refresh();
            }
          },
        );
      } else {
        outputPath = await CompressionService.compressPhoto(
          mediaItems[index].originalPath,
        );
      }

      final compressedSize = CompressionService.getFileSize(outputPath);

      final idx = mediaItems.indexWhere((m) => m.id == itemId);
      if (idx != -1) {
        mediaItems[idx] = mediaItems[idx].copyWith(
          compressedPath: outputPath,
          compressedSizeBytes: compressedSize,
          isCompressed: true,
          isProcessing: false,
          compressionProgress: 1.0,
        );
        mediaItems.refresh();
      }

      // Upload to bot for HD delivery
      Get.snackbar('Uploading...', 'Sending for HD delivery...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1));

      // Show random tip
      Get.snackbar(
        '📌 Quick Tip',
        TipsService.getRandomTip(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blueGrey.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      final uploadService = UploadService();
      //await uploadService.uploadVideo(outputPath);

      Get.snackbar('✅ Done!', 'Check your WhatsApp shortly!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00C853).withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
    } catch (e) {
      final idx = mediaItems.indexWhere((m) => m.id == itemId);
      if (idx != -1) {
        mediaItems[idx] = mediaItems[idx].copyWith(isProcessing: false);
        mediaItems.refresh();
      }
      Get.snackbar('Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  Future<void> shareToWhatsApp(String itemId) async {
    final item = mediaItems.firstWhereOrNull((m) => m.id == itemId);
    if (item == null) return;
    try {
      await WhatsAppService.shareToMyself(item.displayPath,
          isVideo: item.isVideo);
    } catch (e) {
      Get.snackbar('Share Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  Future<void> splitAndShare(String itemId) async {
    final item = mediaItems.firstWhereOrNull((m) => m.id == itemId);
    if (item == null || !item.isVideo) return;

    isLoading.value = true;
    try {
      final sourcePath = item.compressedPath ?? item.originalPath;
      final parts = await CompressionService.splitAndCompress(sourcePath);
      await WhatsAppService.shareMultipleToMyself(parts, isVideo: true);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void removeItem(String itemId) {
    mediaItems.removeWhere((m) => m.id == itemId);
  }

  Future<void> compressAll() async {
    for (final item in mediaItems.where((m) => !m.isCompressed)) {
      await compressItem(item.id);
    }
  }
}
