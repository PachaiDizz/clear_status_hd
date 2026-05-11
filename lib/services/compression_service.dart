import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class CompressionService {
  static const _uuid = Uuid();

  static const int _targetVideoBitrate = 3500;
  static const int _targetAudioBitrate = 128;
  static const int _photoQuality = 98;
  static const int _maxStatusDuration = 30;

  static Future<String> compressVideo(
    String inputPath, {
    void Function(double progress)? onProgress,
  }) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_hd.mp4');

    FFmpegKitConfig.enableStatisticsCallback((stats) {
      final processed = stats.getTime();
      if (onProgress != null && processed > 0) {
        final progress = (processed / 30000).clamp(0.0, 0.95);
        onProgress(progress);
      }
    });

    final command = '-i "$inputPath" '
        '-c:v libx264 '
        '-preset ultrafast '
        '-crf 23 '
        '-b:v ${_targetVideoBitrate}k '
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

  static Future<List<String>> splitVideo(String inputPath) async {
    final duration = await getVideoDuration(inputPath);
    if (duration == null || duration.inSeconds <= _maxStatusDuration) {
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
          '-preset ultrafast '
          '-crf 23 '
          '-b:v ${_targetVideoBitrate}k '
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

  static Future<String> compressPhoto(String inputPath) async {
    final outputDir = await _getOutputDir();
    final outputPath = p.join(outputDir, '${_uuid.v4()}_hd.jpg');

    final result = await FlutterImageCompress.compressAndGetFile(
      inputPath,
      outputPath,
      quality: _photoQuality,
      format: CompressFormat.jpeg,
      minWidth: 4096,
      minHeight: 4096,
      keepExif: true,
    );

    if (result == null) {
      throw Exception('Photo compression failed');
    }

    return result.path;
  }

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
