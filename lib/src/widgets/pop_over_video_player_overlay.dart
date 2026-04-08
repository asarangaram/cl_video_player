import 'package:flutter/material.dart';

import '../gallery_video_player.dart' show VideoPlayerFactory;
import '../video_player_interface.dart';

/// The overlay content for [PopOverVideoPlayer].
///
/// On desktop/tablet: positioned in the bottom-right corner.
/// On mobile (width < 600): positioned at bottom-center with uniform padding.
///
/// The close button is placed above the video area to avoid z-index
/// conflicts with the video player widget.
class PopOverVideoPlayerOverlay extends StatefulWidget {
  const PopOverVideoPlayerOverlay({
    super.key,
    required this.videoUrl,
    this.playerFactory,
    required this.onClose,
  });

  final String videoUrl;
  final VideoPlayerFactory? playerFactory;
  final VoidCallback onClose;

  @override
  State<PopOverVideoPlayerOverlay> createState() =>
      PopOverVideoPlayerOverlayState();
}

class PopOverVideoPlayerOverlayState
    extends State<PopOverVideoPlayerOverlay> {
  VideoPlayerInterface? player;
  bool isInitialized = false;
  bool isPlaying = false;
  bool hasError = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    if (widget.playerFactory == null) {
      setState(() => hasError = true);
      return;
    }

    player = widget.playerFactory!();

    try {
      await player!.initialize(
        onPlayingChanged: (playing) {
          if (mounted) setState(() => isPlaying = playing);
        },
        onPositionChanged: (pos) {
          if (mounted) setState(() => position = pos);
        },
        onDurationChanged: (dur) {
          if (mounted) setState(() => duration = dur);
        },
        onError: (error) {
          if (mounted) setState(() => hasError = true);
        },
      );

      await player!.open(widget.videoUrl, autoPlay: true);

      if (mounted) {
        setState(() => isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => hasError = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // On mobile: bottom-center with uniform 12px padding
    // On desktop: bottom-right with 16px padding
    final videoWidth = isMobile ? screenWidth - 24.0 : 400.0;
    final padding = isMobile
        ? const EdgeInsets.all(12)
        : const EdgeInsets.only(right: 16, bottom: 16);

    // Use Positioned.fill + Align to avoid top-left flash on first frame.
    // A bare Positioned(right:, bottom:) can default to (0,0) before layout.
    return Positioned.fill(
      child: Align(
        alignment: isMobile ? Alignment.bottomCenter : Alignment.bottomRight,
        child: Padding(
          padding: padding,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: videoWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTitleBar(),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildVideoContent(),
                          if (isInitialized && !hasError) buildControls(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Title bar with close button, placed above the video area
  /// to avoid z-index conflicts with the video player.
  Widget buildTitleBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (isInitialized && !hasError)
            Text(
              '${formatDuration(position)} / ${formatDuration(duration)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: const MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVideoContent() {
    if (hasError) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white54, size: 48),
            SizedBox(height: 8),
            Text(
              'Failed to load video',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    if (!isInitialized || player == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return player!.buildVideoWidget(fit: BoxFit.contain, showControls: false);
  }

  Widget buildControls() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: togglePlayPause,
        child: Container(
          color: Colors.transparent,
          child: buildPlayPauseOverlay(),
        ),
      ),
    );
  }

  Widget buildPlayPauseOverlay() {
    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isPlaying ? 0.0 : 1.0,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  String formatDuration(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void togglePlayPause() {
    if (isPlaying) {
      player!.pause();
    } else {
      player!.play();
    }
  }
}
