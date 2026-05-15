import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class CompressionService {
  static const _uuid = Uuid();

  // ── Quality / encoding settings ───────────────────────────
  static const int _crf = 18;
  static const int _audioBitrate = 128;
  static const int _audioSampleRate = 44100;
  static const int _maxStatusDuration = 60; // WhatsApp supports up to 60 s
  static const int _photoDurationSeconds = 5;

  // ── Resolution + bitrate by video length ─────────────────
  static Map<String, int> _getQualitySettings(int durationSeconds) {
    if (durationSeconds <= 30) {
      // ≤30 s → 1080p high quality
      return {'width': 1920, 'maxrate': 4100, 'bufsize': 8500};
    } else {
      // 31–60 s → 720p high quality
      return {'width': 1280, 'maxrate': 3800, 'bufsize': 6500};
    }
  }

  // ══════════════════════════════════════════════════════════
  // Compress video
  // ══════════════════════════════════════════════════════════
  static Future<String> compressVideo(
    String inputPath, {
    void Function(double progress)? onProgress,
  }) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_hd.mp4');

    // Real duration → accurate progress + correct quality tier
    final duration = await getVideoDuration(inputPath);
    final durationSeconds =
        (duration?.inSeconds ?? 30).clamp(1, _maxStatusDuration);
    final durationMs = durationSeconds * 1000;

    final quality = _getQualitySettings(durationSeconds);
    final width = quality['width']!;
    final maxrate = quality['maxrate']!;
    final bufsize = quality['bufsize']!;

    debugPrint(
        '📹 Duration: ${durationSeconds}s → ${width == 1920 ? '1080p' : '720p'}');

    final command = '-i "$inputPath" '
        '-vf "scale=$width:-2:flags=lanczos,format=yuv420p" '
        '-c:v libx264 '
        '-preset fast '
        '-crf $_crf '
        '-maxrate ${maxrate}k '
        '-bufsize ${bufsize}k '
        '-r 30 '
        '-pix_fmt yuv420p '
        '-t $durationSeconds '
        '-c:a aac '
        '-ar $_audioSampleRate '
        '-b:a ${_audioBitrate}k '
        '-movflags +faststart '
        '-y "$outputPath"';

    // FIX 1: use a Completer so we can await the async completion callback
    final completer = Completer<void>();

    // FIX 2: stats callback as a named function declaration (not variable assignment)
    //        and passed as the 3rd parameter of executeAsync — per-session, not global
    void onStats(statistics) {
      final time = statistics.getTime();
      if (onProgress != null && time > 0) {
        onProgress((time / durationMs).clamp(0.0, 0.95));
      }
    }

    await FFmpegKit.executeAsync(
      command,
      // Completion callback
      (session) async {
        completer.complete();
      },
      // Log callback (null = default)
      null,
      // FIX 2: per-session statistics callback
      onStats,
    );

    // Wait for the session to actually finish
    await completer.future;

    // Now safe to read the return code
    final sessions = await FFmpegKit.listSessions();
    final session = sessions.last;
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      onProgress?.call(1.0);
      final size = getFileSize(outputPath);
      debugPrint(
        '✅ Compressed: ${(size / 1048576).toStringAsFixed(2)} MB '
        'at ${width == 1920 ? '1080p' : '720p'}',
      );
      return outputPath;
    } else {
      final logs = await session.getAllLogsAsString();
      throw Exception('FFmpeg compression failed: $logs');
    }
  }

  // ══════════════════════════════════════════════════════════
  // Split video into ≤60 s segments and compress each
  // ══════════════════════════════════════════════════════════
  static Future<List<String>> splitAndCompress(String inputPath) async {
    final duration = await getVideoDuration(inputPath);

    // Already within limit → just compress normally
    if (duration == null || duration.inSeconds <= _maxStatusDuration) {
      return [await compressVideo(inputPath)];
    }

    final outputDir = await _getOutputDir();
    final basename = _uuid.v4();
    final parts = <String>[];

    int start = 0;
    int index = 0;

    while (start < duration.inSeconds) {
      final segmentLength =
          (duration.inSeconds - start).clamp(1, _maxStatusDuration);
      final outPath = p.join(outputDir, '${basename}_p${index + 1}.mp4');

      final quality = _getQualitySettings(segmentLength);
      final width = quality['width']!;
      final maxrate = quality['maxrate']!;
      final bufsize = quality['bufsize']!;

      final command = '-ss $start '
          '-i "$inputPath" '
          '-t $segmentLength '
          '-vf "scale=$width:-2:flags=lanczos,format=yuv420p" '
          '-c:v libx264 '
          '-preset fast '
          '-crf $_crf '
          '-maxrate ${maxrate}k '
          '-bufsize ${bufsize}k '
          '-r 30 '
          '-pix_fmt yuv420p '
          '-c:a aac '
          '-ar $_audioSampleRate '
          '-b:a ${_audioBitrate}k '
          '-movflags +faststart '
          '-y "$outPath"';

      // Each segment: its own session, no shared callbacks
      final session = await FFmpegKit.execute(command);
      if (ReturnCode.isSuccess(await session.getReturnCode())) {
        parts.add(outPath);
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('⚠️ Segment ${index + 1} failed: $logs');
      }

      start += _maxStatusDuration;
      index++;
    }

    return parts;
  }

  // ══════════════════════════════════════════════════════════
  // Convert photo → short MP4 (5 s still video)
  // ══════════════════════════════════════════════════════════
  static Future<String> compressPhoto(String inputPath) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_photo.mp4');

    final command = '-loop 1 '
        '-i "$inputPath" '
        '-vf "scale=1920:-2:flags=lanczos,format=yuv420p" '
        '-c:v libx264 '
        '-preset fast '
        '-crf 18 '
        '-maxrate 5000k '
        '-bufsize 10000k '
        '-r 30 '
        '-pix_fmt yuv420p '
        '-t $_photoDurationSeconds '
        '-an '
        '-movflags +faststart '
        '-y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    }

    // FIX 3: throw instead of silently returning original path
    final logs = await session.getAllLogsAsString();
    throw Exception('Photo compression failed: $logs');
  }

  // ══════════════════════════════════════════════════════════
  // Utilities
  // ══════════════════════════════════════════════════════════

  /// Returns video duration by parsing FFmpeg probe output.
  static Future<Duration?> getVideoDuration(String path) async {
    try {
      final session = await FFmpegKit.execute('-i "$path" -f null -');
      final logs = await session.getAllLogsAsString();
      final match = RegExp(
        r'Duration:\s+(\d+):(\d+):(\d+\.\d+)',
      ).firstMatch(logs ?? '');

      if (match != null) {
        final h = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final s = double.parse(match.group(3)!);
        return Duration(seconds: h * 3600 + m * 60 + s.toInt());
      }
    } catch (_) {}
    return null;
  }

  /// Returns file size in bytes, 0 on error.
  static int getFileSize(String path) {
    try {
      return File(path).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  /// Deletes all temp compressed files.
  static Future<void> cleanupTempFiles() async {
    try {
      final dir = Directory(await _getOutputDir());
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  /// Returns (and creates if needed) the temp output directory.
  static Future<String> _getOutputDir() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(p.join(tempDir.path, 'hd_status_output'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }
}

// App flow:
// Choose Video/Photo → Compress → Upload to bot →
// Bot sends HD file to WhatsApp → User forwards to Status
