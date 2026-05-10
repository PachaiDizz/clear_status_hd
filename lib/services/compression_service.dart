import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CompressionService
///
/// HOW IT WORKS (the secret behind PureStatus):
///
/// WhatsApp re-compresses any video that exceeds its internal limits.
/// Its limit is roughly 16 MB / 30 sec → ~3800 kbps bitrate.
///
/// So we pre-compress to ~3500 kbps (just under the limit) using H.264
/// with a high-quality CRF and faststart flag. This means WhatsApp barely
/// touches it, resulting in much better quality than uploading the raw original.
///
/// For photos, we convert to a lightly-compressed JPEG at 95% quality,
/// which WhatsApp handles without heavy re-compression.
/// ─────────────────────────────────────────────────────────────────────────────
class CompressionService {
  static const _uuid = Uuid();

  // Target video bitrate (kbps) — just under WhatsApp's threshold
  static const int _targetVideoBitrate = 3500;
  // Audio bitrate
  static const int _targetAudioBitrate = 128;
  // Max photo quality (0–100)
  static const int _photoQuality = 92;
  // WhatsApp status max duration (seconds)
  static const int _maxStatusDuration = 30;

  /// Compress a video for WhatsApp Status
  /// Returns the output file path on success, throws on failure.
  static Future<String> compressVideo(
    String inputPath, {
    void Function(double progress)? onProgress,
  }) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_hd.mp4');

    // Enable statistics callback for progress tracking
    FFmpegKitConfig.enableStatisticsCallback((stats) {
      // We estimate progress based on time processed vs duration
      // This is a simplified progress; for precise progress, parse duration first
      final processed = stats.getTime(); // milliseconds processed
      if (onProgress != null && processed > 0) {
        // Approximate: assume average 30s video
        final progress = (processed / 30000).clamp(0.0, 0.95);
        onProgress(progress);
      }
    });

    // FFmpeg command:
    // -i input                      → input file
    // -c:v libx264                  → H.264 codec (best compatibility)
    // -preset fast                  → encoding speed vs quality trade-off
    // -crf 23                       → quality level (18=lossless, 28=low; 23 is sweet spot)
    // -b:v 3500k                    → target video bitrate
    // -maxrate 3800k                → max bitrate cap
    // -bufsize 7600k                → buffer for bitrate control
    // -vf scale=1280:-2             → scale to 1280px wide, height auto (keeps 720p)
    // -c:a aac                      → AAC audio codec
    // -b:a 128k                     → audio bitrate
    // -movflags +faststart          → move metadata to front (required for streaming)
    // -y                            → overwrite output

    final command = '-i "$inputPath" '
        '-c:v libx264 '
        '-preset fast '
        '-crf 23 '
        '-b:v ${_targetVideoBitrate}k '
        '-maxrate ${_targetVideoBitrate + 300}k '
        '-bufsize ${(_targetVideoBitrate * 2)}k '
        '-vf "scale=1280:-2" '
        '-c:a aac '
        '-b:a ${_targetAudioBitrate}k '
        '-movflags +faststart '
        '-y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      onProgress?.call(1.0);
      return outputPath;
    } else {
      final logs = await session.getAllLogsAsString();
      throw Exception('Video compression failed: $logs');
    }
  }

  /// Split a video into ≤30-second chunks for WhatsApp Status
  /// Returns list of output file paths.
  static Future<List<String>> splitVideo(String inputPath) async {
    // First get video duration
    final duration = await getVideoDuration(inputPath);
    if (duration == null || duration.inSeconds <= _maxStatusDuration) {
      // No split needed
      return [inputPath];
    }

    final outputDir = await _getOutputDir();
    final basename = _uuid.v4();
    final outputPaths = <String>[];

    int segmentStart = 0;
    int partIndex = 0;

    while (segmentStart < duration.inSeconds) {
      final outputPath =
          p.join(outputDir, '${basename}_part${partIndex + 1}.mp4');
      final segDuration = _maxStatusDuration;

      final command = '-i "$inputPath" '
          '-ss $segmentStart '
          '-t $segDuration '
          '-c:v libx264 '
          '-preset fast '
          '-crf 23 '
          '-b:v ${_targetVideoBitrate}k '
          '-maxrate ${_targetVideoBitrate + 300}k '
          '-bufsize ${(_targetVideoBitrate * 2)}k '
          '-vf "scale=1280:-2" '
          '-c:a aac '
          '-b:a ${_targetAudioBitrate}k '
          '-movflags +faststart '
          '-y "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        outputPaths.add(outputPath);
      }

      segmentStart += segDuration;
      partIndex++;
    }

    return outputPaths;
  }

  /// Compress a photo for WhatsApp Status
  /// Returns the output file path on success.
  static Future<String> compressPhoto(String inputPath) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_hd.jpg');

    final result = await FlutterImageCompress.compressAndGetFile(
      inputPath,
      outputPath,
      quality: _photoQuality,
      format: CompressFormat.jpeg,
      // Keep original dimensions — we only optimize encoding, not resolution
      minWidth: 1920,
      minHeight: 1920,
      keepExif: true,
    );

    if (result == null) {
      throw Exception('Photo compression failed');
    }

    return result.path;
  }

  /// Get video duration using FFprobe via FFmpegKit
  static Future<Duration?> getVideoDuration(String path) async {
    try {
      final session = await FFmpegKit.execute('-i "$path" -f null -');
      final logs = await session.getAllLogsAsString();
      final regex = RegExp(r'Duration:\s+(\d+):(\d+):(\d+\.\d+)');
      final match = regex.firstMatch(logs ?? '');
      if (match != null) {
        final hours = int.parse(match.group(1)!);
        final minutes = int.parse(match.group(2)!);
        final seconds = double.parse(match.group(3)!);
        final totalSeconds = hours * 3600 + minutes * 60 + seconds.toInt();
        return Duration(seconds: totalSeconds);
      }
    } catch (_) {}
    return null;
  }

  /// Get file size in bytes
  static int getFileSize(String path) {
    try {
      return File(path).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  /// Clean up all compressed files from temp directory
  static Future<void> cleanupTempFiles() async {
    try {
      final dir = Directory(await _getOutputDir());
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  static Future<String> _getOutputDir() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(p.join(tempDir.path, 'hd_status_output'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }
}
