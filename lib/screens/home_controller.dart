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
import '../services/usage_service.dart';
import '../utils/app_theme.dart';
import '../screens/limit_reached_screen.dart';

class HomeController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  final RxList<MediaItem> mediaItems = <MediaItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt selectedTabIndex = 0.obs;

  // ══════════════════════════════════════════════════════════
  // Pick media
  // ══════════════════════════════════════════════════════════

  Future<void> pickVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (file == null) return;

      final size = await File(file.path).length();
      final duration = await CompressionService.getVideoDuration(file.path);

      mediaItems.add(MediaItem(
        id: _uuid.v4(),
        originalPath: file.path,
        type: MediaType.video,
        originalSizeBytes: size,
        duration: duration,
      ));
    } catch (e) {
      _showError('Could not pick video: $e');
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

      mediaItems.add(MediaItem(
        id: _uuid.v4(),
        originalPath: file.path,
        type: MediaType.photo,
        originalSizeBytes: size,
      ));
    } catch (e) {
      _showError('Could not pick photo: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // Compress
  // ══════════════════════════════════════════════════════════

  Future<void> compressItem(String itemId) async {
    // Check verification
    if (!WhatsAppVerifyService.isVerified()) {
      Get.snackbar(
        'Verification Required',
        'Please verify your WhatsApp number first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      Get.offNamed('/setup');
      return;
    }

    // Check usage limit → show LimitReachedScreen
    if (!UsageService.canSend()) {
      Get.to(() => const LimitReachedScreen());
      return;
    }

    // ── Mark as processing ───────────────────────────────
    _updateItem(
        itemId,
        (item) => item.copyWith(
              isProcessing: true,
              compressionProgress: 0.0,
            ));

    try {
      final item = _findItem(itemId);
      if (item == null) return;

      // ── Compress ─────────────────────────────────────
      final String outputPath;

      if (item.isVideo) {
        outputPath = await CompressionService.compressVideo(
          item.originalPath,
          onProgress: (progress) {
            _updateItem(
                itemId,
                (m) => m.copyWith(
                      compressionProgress: progress,
                    ));
          },
        );
      } else {
        outputPath = await CompressionService.compressPhoto(
          item.originalPath,
        );
      }

      final compressedSize = CompressionService.getFileSize(outputPath);

      // ── Mark as done ──────────────────────────────────
      _updateItem(
          itemId,
          (m) => m.copyWith(
                compressedPath: outputPath,
                compressedSizeBytes: compressedSize,
                isCompressed: true,
                isProcessing: false,
                compressionProgress: 1.0,
              ));

      // ── Upload ────────────────────────────────────────
      Get.snackbar(
        'Uploading…',
        'Sending for HD delivery…',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      await UploadService.uploadVideo(outputPath);

      // Record usage
      UsageService.recordSend();

      // ── Show tip after upload completes ───────────────
      await Future.delayed(const Duration(seconds: 2));
      Get.snackbar(
        '📌 Quick Tip',
        TipsService.getRandomTip(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blueGrey.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      // ── Success ───────────────────────────────────────
      await Future.delayed(const Duration(seconds: 5));
      Get.snackbar(
        '✅ Done!',
        'Check your WhatsApp shortly!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.9),
        colorText: Colors.black,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      // ── Reset processing state on failure ─────────────
      _updateItem(
          itemId,
          (m) => m.copyWith(
                isProcessing: false,
                compressionProgress: 0.0,
              ));
      _showError(e.toString());
    }
  }

  // ══════════════════════════════════════════════════════════
  // Share
  // ══════════════════════════════════════════════════════════

  Future<void> shareToWhatsApp(String itemId) async {
    final item = _findItem(itemId);
    if (item == null) return;

    try {
      await WhatsAppService.shareToMyself(
        item.displayPath,
        isVideo: item.isVideo,
      );
    } catch (e) {
      _showError('Share failed: $e');
    }
  }

  Future<void> splitAndShare(String itemId) async {
    final item = _findItem(itemId);
    if (item == null || !item.isVideo) return;

    isLoading.value = true;
    try {
      final sourcePath = item.compressedPath ?? item.originalPath;
      final parts = await CompressionService.splitAndCompress(sourcePath);
      await WhatsAppService.shareMultipleToMyself(parts, isVideo: true);
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // Manage list
  // ══════════════════════════════════════════════════════════

  void removeItem(String itemId) {
    mediaItems.removeWhere((m) => m.id == itemId);
  }

  Future<void> compressAll() async {
    final uncompressed = mediaItems
        .where((m) => !m.isCompressed && !m.isProcessing)
        .map((m) => m.id)
        .toList();

    for (final id in uncompressed) {
      await compressItem(id);
    }
  }

  // ══════════════════════════════════════════════════════════
  // Private helpers
  // ══════════════════════════════════════════════════════════

  MediaItem? _findItem(String itemId) {
    return mediaItems.firstWhereOrNull((m) => m.id == itemId);
  }

  void _updateItem(String itemId, MediaItem Function(MediaItem) transform) {
    final idx = mediaItems.indexWhere((m) => m.id == itemId);
    if (idx == -1) return;
    mediaItems[idx] = transform(mediaItems[idx]);
    mediaItems.refresh();
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.errorColor.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}
