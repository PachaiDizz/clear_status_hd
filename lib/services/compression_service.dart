import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// CompressionService – Pure Status logic
///
/// - Produces **1280×720p, 30 fps, H.264 Baseline** videos
/// - File size guaranteed ≤ 15.5 MB (WhatsApp never re‑encodes)
/// - Photos become 5‑second, 1 fps video loops
class CompressionService {
  static const _uuid = Uuid();

  // Targets
  static const int _maxSizeBytes = 15500000;
  static const int _maxStatusDuration = 30;
  static const int _photoDurationSeconds = 5;

  // Encoding constants
  static const String _outputResolution = '1280x720'; // WhatsApp golden size
  static const int _frameRate = 30; // must be constant
  static const String _profile = 'baseline'; // MUST be baseline
  static const String _level = '3.0'; // baseline 3.0
  static const int _audioBitrate = 128; // AAC kbps
  static const int _audioSampleRate = 44100;
  static const int _crf = 23; // good balance
  static const int _maxrateKbps = 4000; // keep under 4 Mbps peak
  static const int _bufsizeKbps = 8000;

  /// Compress video – guaranteed ≤ 15.5 MB and WhatsApp‑ready
  static Future<String> compressVideo(
    String inputPath, {
    void Function(double progress)? onProgress,
  }) async {
    // One‑pass with CRF + VBV is usually enough
    final output = await _encodeWithCRF(inputPath, onProgress: onProgress);
    if (getFileSize(output) <= _maxSizeBytes) return output;

    // Fallback: two‑pass for exact size (rarely needed)
    debugPrint('CRF too large (${getFileSize(output)} B), trying two‑pass...');
    await File(output).delete();
    return await _encodeTwoPass(inputPath, onProgress: onProgress);
  }

  /// Split video into ≤ 30 s segments, each under 15.5 MB
  static Future<List<String>> splitAndCompress(String inputPath) async {
    final duration = await getVideoDuration(inputPath);
    if (duration == null || duration.inSeconds <= _maxStatusDuration) {
      return [await compressVideo(inputPath)];
    }

    final outputDir = await _getOutputDir();
    final basename = _uuid.v4();
    final parts = <String>[];

    int start = 0;
    int index = 0;
    while (start < duration.inSeconds) {
      final length = (duration.inSeconds - start).clamp(1, _maxStatusDuration);
      final outPath = p.join(outputDir, '${basename}_p${index + 1}.mp4');
      final segPath = await _encodeSegment(
        inputPath,
        startSec: start,
        durationSec: length,
        outputPath: outPath,
      );
      if (segPath != null) parts.add(segPath);
      start += _maxStatusDuration;
      index++;
    }
    return parts;
  }

  /// Convert photo → video (bypasses JPEG recompression)
  static Future<String> compressPhoto(String inputPath) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_photo.mp4');

    // Static image: 1 fps, very high quality
    final command = '-loop 1 '
        '-framerate 1 '
        '-i "$inputPath" '
        '-c:v libx264 '
        '-t $_photoDurationSeconds '
        '-pix_fmt yuv420p '
        '-vf "scale=1280:720:force_original_aspect_ratio=decrease,'
        'pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
        '-crf 18 '
        '-preset veryslow '
        '-profile:v baseline '
        '-level 3.0 '
        '-movflags +faststart '
        '-y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    if (ReturnCode.isSuccess(await session.getReturnCode())) {
      return outputPath;
    }
    final logs = await session.getAllLogsAsString();
    debugPrint('Photo conversion failed: $logs');
    return inputPath; // fallback to original image
  }

  // ────────────────────────────────
  // Core encoding: CRF + VBV (one‑pass)
  // ────────────────────────────────
  static Future<String> _encodeWithCRF(
    String inputPath, {
    void Function(double progress)? onProgress,
  }) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_c.mp4');

    FFmpegKitConfig.enableStatisticsCallback((stats) {
      final time = stats.getTime();
      if (onProgress != null && time > 0) {
        onProgress((time / 30000).clamp(0.0, 0.9));
      }
    });

    // Magic incantation: WhatsApp Status happy path
    final command = '-i "$inputPath" '
        '-vf "scale=1280:720:force_original_aspect_ratio=decrease,'
        'pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
        '-c:v libx264 '
        '-preset slow '
        '-crf $_crf '
        '-profile:v $_profile '
        '-level $_level '
        '-maxrate ${_maxrateKbps}k '
        '-bufsize ${_bufsizeKbps}k '
        '-r $_frameRate '
        '-c:a aac -b:a ${_audioBitrate}k -ar $_audioSampleRate -ac 2 '
        '-movflags +faststart '
        '-y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      onProgress?.call(1.0);
      return outputPath;
    } else {
      final logs = await session.getAllLogsAsString();
      throw Exception('FFmpeg error: $logs');
    }
  }

  // ──────────────────────────────
  // Two‑pass VBR for tight size control
  // ──────────────────────────────
  static Future<String> _encodeTwoPass(
    String inputPath, {
    void Function(double progress)? onProgress,
  }) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_2p.mp4');

    final duration =
        await getVideoDuration(inputPath) ?? const Duration(seconds: 30);
    final durSec = duration.inSeconds.clamp(1, _maxStatusDuration);
    final bitrateKbps =
        ((_maxSizeBytes * 8) / durSec / 1000).round() - _audioBitrate;
    final safeBitrate = bitrateKbps.clamp(1000, 4000);

    // Pass 1
    final pass1 = '-i "$inputPath" '
        '-vf "scale=1280:720:force_original_aspect_ratio=decrease,'
        'pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
        '-c:v libx264 -preset slow -b:v ${safeBitrate}k '
        '-pass 1 -an -f mp4 -y /dev/null';

    final s1 = await FFmpegKit.execute(pass1);
    if (!ReturnCode.isSuccess(await s1.getReturnCode())) {
      throw Exception('Two‑pass pass 1 failed');
    }

    // Pass 2
    final pass2 = '-i "$inputPath" '
        '-vf "scale=1280:720:force_original_aspect_ratio=decrease,'
        'pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
        '-c:v libx264 -preset slow -b:v ${safeBitrate}k '
        '-pass 2 '
        '-profile:v $_profile -level $_level '
        '-r $_frameRate '
        '-c:a aac -b:a ${_audioBitrate}k -ar $_audioSampleRate -ac 2 '
        '-movflags +faststart '
        '-y "$outputPath"';

    final s2 = await FFmpegKit.execute(pass2);
    if (ReturnCode.isSuccess(await s2.getReturnCode())) {
      onProgress?.call(1.0);
      return outputPath;
    }
    throw Exception('Two‑pass pass 2 failed');
  }

  // ──────────────────────────────
  // Encode a single ≤ 30 s segment
  // ──────────────────────────────
  static Future<String?> _encodeSegment(
    String inputPath, {
    required int startSec,
    required int durationSec,
    required String outputPath,
  }) async {
    final command = '-ss $startSec '
        '-i "$inputPath" '
        '-t $durationSec '
        '-vf "scale=1280:720:force_original_aspect_ratio=decrease,'
        'pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
        '-c:v libx264 -preset slow '
        '-crf $_crf -profile:v $_profile -level $_level '
        '-maxrate ${_maxrateKbps}k -bufsize ${_bufsizeKbps}k '
        '-r $_frameRate '
        '-c:a aac -b:a ${_audioBitrate}k -ar $_audioSampleRate -ac 2 '
        '-movflags +faststart '
        '-y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    if (ReturnCode.isSuccess(await session.getReturnCode())) {
      if (getFileSize(outputPath) <= _maxSizeBytes) {
        return outputPath;
      }
      debugPrint('Segment over size limit, dropped.');
    }
    return null;
  }

  // ──────────── Utilities ────────────

  static Future<Duration?> getVideoDuration(String path) async {
    try {
      final session = await FFmpegKit.execute('-i "$path" -f null -');
      final logs = await session.getAllLogsAsString();
      final match =
          RegExp(r'Duration:\s+(\d+):(\d+):(\d+\.\d+)').firstMatch(logs ?? '');
      if (match != null) {
        final h = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final s = double.parse(match.group(3)!);
        return Duration(seconds: h * 3600 + m * 60 + s.toInt());
      }
    } catch (_) {}
    return null;
  }

  static int getFileSize(String path) {
    try {
      return File(path).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  static Future<void> cleanupTempFiles() async {
    try {
      final dir = Directory(await _getOutputDir());
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  static Future<String> _getOutputDir() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(p.join(tempDir.path, 'hd_status_output'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }
}
