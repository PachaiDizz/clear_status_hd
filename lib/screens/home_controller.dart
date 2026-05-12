import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/media_item.dart';
import '../services/compression_service.dart';
import '../services/share_service.dart';
import '../services/firebase_upload_service.dart';
import '../services/whatsapp_service.dart';

class HomeController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  // Observable state
  final RxList<MediaItem> mediaItems = <MediaItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt selectedTabIndex = 0.obs; // 0=Video, 1=Photo

  // Pick a video from gallery
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
      Get.snackbar(
        'Error',
        'Could not pick video: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Pick a photo from gallery
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
      Get.snackbar(
        'Error',
        'Could not pick photo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Compress a media item
  Future<void> compressItem(String itemId) async {
    final index = mediaItems.indexWhere((m) => m.id == itemId);
    if (index == -1) return;

    // Mark as processing
    mediaItems[index] = mediaItems[index].copyWith(
      isProcessing: true,
      compressionProgress: 0.0,
    );
    mediaItems.refresh();

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

      // Upload to Firebase so bot can deliver it
      Get.snackbar(
        'Uploading...',
        'Sending to server for HD delivery...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );

      final uploadService = FirebaseUploadService();
      await uploadService.uploadVideo(outputPath, onProgress: (progress) {
        final idx2 = mediaItems.indexWhere((m) => m.id == itemId);
        if (idx2 != -1) {
          mediaItems[idx2] = mediaItems[idx2].copyWith(
            compressionProgress: 0.95 + (progress * 0.05),
          );
          mediaItems.refresh();
        }
      });

      Get.snackbar(
        '✅ Done!',
        'Uploaded. Check your WhatsApp shortly!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00C853).withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      final idx = mediaItems.indexWhere((m) => m.id == itemId);
      if (idx != -1) {
        mediaItems[idx] = mediaItems[idx].copyWith(
          isProcessing: false,
        );
        mediaItems.refresh();
      }
      Get.snackbar(
        'Compression Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Share single item to WhatsApp
  Future<void> shareToWhatsApp(String itemId) async {
    final item = mediaItems.firstWhereOrNull((m) => m.id == itemId);
    if (item == null) return;

    try {
      await WhatsAppService.shareToMyself(item.displayPath,
          isVideo: item.isVideo);
    } catch (e) {
      Get.snackbar(
        'Share Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Split video and share all parts
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

  // Remove item from list
  void removeItem(String itemId) {
    mediaItems.removeWhere((m) => m.id == itemId);
  }

  // Compress all pending items
  Future<void> compressAll() async {
    for (final item in mediaItems.where((m) => !m.isCompressed)) {
      await compressItem(item.id);
    }
  }
}
