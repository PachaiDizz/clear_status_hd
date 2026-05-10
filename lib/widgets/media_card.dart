import 'dart:io';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:video_player/video_player.dart';

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
  VideoPlayerController? _videoController;
  bool _thumbnailReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo) {
      _initVideoThumbnail();
    }
  }

  void _initVideoThumbnail() async {
    _videoController = VideoPlayerController.file(
      File(widget.item.originalPath),
    );
    await _videoController!.initialize();
    if (mounted) setState(() => _thumbnailReady = true);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ──
          _buildThumbnail(),

          // ── Info Row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildInfoRow(),
          ),

          // ── Progress bar (during compression) ──
          if (widget.item.isProcessing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildProgressBar(),
            ),

          // ── Actions ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 200,
            child: widget.item.isVideo
                ? (_thumbnailReady && _videoController != null
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    : _shimmer())
                : Image.file(
                    File(widget.item.originalPath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
          ),
          // Type badge
          Positioned(
            top: 12,
            left: 12,
            child: _badge(
              widget.item.isVideo ? '🎬 Video' : '📷 Photo',
              AppTheme.primaryColor,
            ),
          ),
          // Duration badge for videos
          if (widget.item.duration != null)
            Positioned(
              top: 12,
              right: 12,
              child: _badge(
                _formatDuration(widget.item.duration!),
                Colors.black54,
              ),
            ),
          // Compressed overlay
          if (widget.item.isCompressed)
            Positioned(
              bottom: 12,
              right: 12,
              child: _badge('✅ HD Ready', AppTheme.primaryColor),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original: ${widget.item.originalSizeFormatted}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (widget.item.isCompressed) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Compressed: ${widget.item.compressedSizeFormatted}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.item.compressionRatio != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${widget.item.compressionRatio!.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        // Remove button
        IconButton(
          onPressed: widget.onRemove,
          icon: const Icon(Icons.close_rounded, size: 20),
          color: AppTheme.textSecondary,
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compressing... ${(widget.item.compressionProgress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          lineHeight: 6,
          percent: widget.item.compressionProgress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey.withOpacity(0.2),
          linearGradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.accentColor],
          ),
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
          animation: true,
          animateFromLastPercent: true,
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (widget.item.isProcessing) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    if (!widget.item.isCompressed) {
      // Not yet compressed — show compress button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.onCompress,
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: const Text('Compress for HD Status'),
        ),
      );
    }

    // Already compressed — show share options
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onShare,
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Share to WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366), // WhatsApp green
            ),
          ),
        ),
        if (widget.item.isVideo &&
            widget.item.duration != null &&
            widget.item.duration!.inSeconds > 30) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: widget.onSplitShare,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor.withOpacity(0.2),
              foregroundColor: AppTheme.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            child: const Icon(Icons.content_cut_rounded, size: 18),
          ),
        ],
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _shimmer() {
    return Container(
      color: Colors.grey.withOpacity(0.2),
      child: const Center(
        child: Icon(Icons.videocam_rounded, color: Colors.grey, size: 48),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
