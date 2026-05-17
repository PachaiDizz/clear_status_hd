import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/media_item.dart';
import '../utils/app_theme.dart';

class MediaCard extends StatefulWidget {
  final MediaItem item;
  final VoidCallback onCompress;
  final VoidCallback onShare;
  final VoidCallback onSplitShare;
  final VoidCallback onRemove;

  const MediaCard({
    super.key,
    required this.item,
    required this.onCompress,
    required this.onShare,
    required this.onSplitShare,
    required this.onRemove,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  String? _thumbnailPath;
  bool _thumbLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      if (widget.item.isVideo) {
        final path = await VideoThumbnail.thumbnailFile(
          video: widget.item.originalPath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 160,
          quality: 72,
        );
        if (mounted)
          setState(() {
            _thumbnailPath = path;
            _thumbLoading = false;
          });
      } else {
        // Photos: just show the original directly
        if (mounted)
          setState(() {
            _thumbLoading = false;
          });
      }
    } catch (_) {
      if (mounted) setState(() => _thumbLoading = false);
    }
  }

  // ── helpers ─────────────────────────────────────────────
  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _fileName {
    return widget.item.originalPath.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      onDismissed: (_) => widget.onRemove(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail row ───────────────────────────────
            _buildThumbnailRow(item),

            // ── Progress bar (only while compressing) ───────
            if (item.isProcessing ||
                (item.compressionProgress > 0 && !item.isCompressed))
              _buildProgressSection(item),

            // ── Action row ──────────────────────────────────
            _buildActionRow(item),
          ],
        ),
      ),
    );
  }

  // ── Thumbnail + meta ──────────────────────────────────────
  Widget _buildThumbnailRow(MediaItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          _buildThumb(item),
          const SizedBox(width: 14),

          // Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File name
                Text(
                  _fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),

                // Size row
                Row(
                  children: [
                    Text(
                      _formatBytes(item.originalSizeBytes),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    if (item.isCompressed &&
                        item.compressedSizeBytes != null) ...[
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.25),
                      ),
                      Text(
                        _formatBytes(item.compressedSizeBytes!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),

                // Duration (video only)
                if (item.isVideo && item.duration != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatDuration(item.duration),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.28),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Status pill
                _buildStatusPill(item),
              ],
            ),
          ),

          // Remove button
          GestureDetector(
            onTap: widget.onRemove,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actual thumbnail widget ───────────────────────────────
  Widget _buildThumb(MediaItem item) {
    Widget inner;

    if (_thumbLoading) {
      inner = Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
        ),
      );
    } else if (item.isVideo && _thumbnailPath != null) {
      inner = Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_thumbnailPath!),
              fit: BoxFit.cover,
            ),
          ),
          // Play icon overlay
          Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      );
    } else if (!item.isVideo) {
      // Photo: show actual image
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(item.originalPath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbFallback(item),
        ),
      );
    } else {
      inner = _thumbFallback(item);
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.thumbDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: inner,
    );
  }

  Widget _thumbFallback(MediaItem item) {
    return Center(
      child: Icon(
        item.isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
        color: Colors.white.withOpacity(0.2),
        size: 28,
      ),
    );
  }

  // ── Status pill ───────────────────────────────────────────
  Widget _buildStatusPill(MediaItem item) {
    String label;
    Color bg;
    Color fg;
    IconData icon;

    if (item.isCompressed) {
      label = 'Done';
      bg = AppTheme.primaryColor.withOpacity(0.12);
      fg = AppTheme.primaryColor;
      icon = Icons.check_circle_rounded;
    } else if (item.isProcessing) {
      label = 'Compressing…';
      bg = Colors.white.withOpacity(0.05);
      fg = Colors.white.withOpacity(0.55);
      icon = Icons.hourglass_bottom_rounded;
    } else {
      label = 'Tap to compress';
      bg = Colors.white.withOpacity(0.04);
      fg = Colors.white.withOpacity(0.35);
      icon = Icons.compress_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────
  Widget _buildProgressSection(MediaItem item) {
    final pct = (item.compressionProgress * 100).toInt();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: item.compressionProgress,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action row ────────────────────────────────────────────
  Widget _buildActionRow(MediaItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          if (!item.isCompressed && !item.isProcessing)
            Expanded(
              child: _ActionButton(
                label: 'Compress',
                icon: Icons.compress_rounded,
                onTap: widget.onCompress,
                primary: true,
              ),
            ),
          if (item.isCompressed) ...[
            Expanded(
              child: _ActionButton(
                label: 'Send to WhatsApp',
                icon: Icons.send_rounded,
                onTap: widget.onShare,
                primary: true,
              ),
            ),
            if (item.isVideo) ...[
              const SizedBox(width: 8),
              _ActionButton(
                label: 'Split',
                icon: Icons.call_split_rounded,
                onTap: widget.onSplitShare,
                primary: false,
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Dismiss background ────────────────────────────────────
  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: AppTheme.errorColor, size: 22),
          const SizedBox(height: 4),
          Text(
            'Remove',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable action button ──────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
        decoration: BoxDecoration(
          color:
              primary ? AppTheme.primaryColor : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: primary ? Colors.black : Colors.white.withOpacity(0.55),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primary ? Colors.black : Colors.white.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
