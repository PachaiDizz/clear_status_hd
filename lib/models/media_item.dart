enum MediaType { photo, video }

class MediaItem {
  final String id;
  final String originalPath;
  String? compressedPath;
  final MediaType type;
  final int originalSizeBytes;
  int? compressedSizeBytes;
  final Duration? duration; // for videos
  bool isCompressed;
  bool isProcessing;
  double compressionProgress;

  MediaItem({
    required this.id,
    required this.originalPath,
    this.compressedPath,
    required this.type,
    required this.originalSizeBytes,
    this.compressedSizeBytes,
    this.duration,
    this.isCompressed = false,
    this.isProcessing = false,
    this.compressionProgress = 0.0,
  });

  bool get isVideo => type == MediaType.video;
  bool get isPhoto => type == MediaType.photo;

  String get displayPath => compressedPath ?? originalPath;

  String get originalSizeFormatted => _formatBytes(originalSizeBytes);
  String get compressedSizeFormatted =>
      compressedSizeBytes != null ? _formatBytes(compressedSizeBytes!) : '—';

  double? get compressionRatio {
    if (compressedSizeBytes == null) return null;
    return (1 - compressedSizeBytes! / originalSizeBytes) * 100;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  MediaItem copyWith({
    String? compressedPath,
    int? compressedSizeBytes,
    bool? isCompressed,
    bool? isProcessing,
    double? compressionProgress,
  }) {
    return MediaItem(
      id: id,
      originalPath: originalPath,
      compressedPath: compressedPath ?? this.compressedPath,
      type: type,
      originalSizeBytes: originalSizeBytes,
      compressedSizeBytes: compressedSizeBytes ?? this.compressedSizeBytes,
      duration: duration,
      isCompressed: isCompressed ?? this.isCompressed,
      isProcessing: isProcessing ?? this.isProcessing,
      compressionProgress: compressionProgress ?? this.compressionProgress,
    );
  }
}
