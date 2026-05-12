import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// CompressionService – Pure Status confirmed settings
///
/// All values confirmed from libstub.so binary analysis:
/// CRF 23, maxrate 1600k, 29.97 fps, main profile, 44.1kHz audio
class CompressionService {
  static const _uuid = Uuid();

  // Pure Status confirmed values from libstub.so
  static const int _crf = 23;
  static const int _maxrateKbps = 1600;
  static const int _bufsizeKbps = 3200; // 2x maxrate
  static const double _frameRate = 29.97;
  static const String _profile = 'main';
  static const int _audioBitrate = 128;
  static const int _audioSampleRate = 44100;
  static const int _maxStatusDuration = 30;
  static const int _photoDurationSeconds = 5;

  /// Compress video – Pure Status exact settings
  static Future<String> compressVideo(
    String inputPath, {
    void Function(double progress)? onProgress,
  }) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_hd.mp4');

    FFmpegKitConfig.enableStatisticsCallback((stats) {
      final time = stats.getTime();
      if (onProgress != null && time > 0) {
        onProgress((time / 30000).clamp(0.0, 0.95));
      }
    });

    // Pure Status exact command from libstub.so
    final command = '-i "$inputPath" '
        '-vf "scale=1280:720:force_original_aspect_ratio=decrease,'
        'pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
        '-c:v libx264 '
        '-preset medium '
        '-crf $_crf '
        '-profile:v $_profile '
        '-maxrate ${_maxrateKbps}k '
        '-bufsize ${_bufsizeKbps}k '
        '-r $_frameRate '
        '-pix_fmt yuv420p '
        '-c:a aac '
        '-ar $_audioSampleRate '
        '-b:a ${_audioBitrate}k '
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

  /// Split video into ≤30s segments
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

      final command = '-ss $start '
          '-i "$inputPath" '
          '-t $length '
          '-vf "scale=1280:720:force_original_aspect_ratio=decrease,'
          'pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
          '-c:v libx264 '
          '-preset medium '
          '-crf $_crf '
          '-profile:v $_profile '
          '-maxrate ${_maxrateKbps}k '
          '-bufsize ${_bufsizeKbps}k '
          '-r $_frameRate '
          '-pix_fmt yuv420p '
          '-c:a aac '
          '-ar $_audioSampleRate '
          '-b:a ${_audioBitrate}k '
          '-movflags +faststart '
          '-y "$outPath"';

      final session = await FFmpegKit.execute(command);
      if (ReturnCode.isSuccess(await session.getReturnCode())) {
        parts.add(outPath);
      }
      start += _maxStatusDuration;
      index++;
    }
    return parts;
  }

  /// Convert photo to video – Pure Status confirmed filter
  static Future<String> compressPhoto(String inputPath) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_photo.mp4');

    // Pure Status image loop filter from libstub.so
    final command = '-loop 1 '
        '-i "$inputPath" '
        '-filter:v "loop=-1:1:0,trim=duration=$_photoDurationSeconds,'
        'crop=trunc(iw/2)*2:trunc(ih/2)*2,'
        'scale=1280:720:force_original_aspect_ratio=decrease,'
        'pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
        '-c:v libx264 '
        '-preset medium '
        '-crf $_crf '
        '-profile:v $_profile '
        '-maxrate ${_maxrateKbps}k '
        '-bufsize ${_bufsizeKbps}k '
        '-r $_frameRate '
        '-pix_fmt yuv420p '
        '-t $_photoDurationSeconds '
        '-an '
        '-movflags +faststart '
        '-y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    if (ReturnCode.isSuccess(await session.getReturnCode())) {
      return outputPath;
    }
    final logs = await session.getAllLogsAsString();
    debugPrint('Photo conversion failed: $logs');
    return inputPath;
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
