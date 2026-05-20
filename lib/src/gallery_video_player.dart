import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'video_player_interface.dart';
import 'video_url_utils.dart';

typedef OnPlayStateChanged = void Function(
  String videoId, {
  required bool isPlaying,
});
typedef VideoPlayerFactory = VideoPlayerInterface Function();

/// Gallery video player that shows poster by default.
///
/// Behavior:
/// - Default: Shows poster image with play button overlay
/// - On play click: Inline video playback
/// - When deactivated or scrolled out of view: Resets to poster
class GalleryVideoPlayer extends StatefulWidget {
  const GalleryVideoPlayer({
    required this.videoUrl,
    required this.videoId,
    required this.onPlayStateChanged,
    required this.isActiveVideo,
    required this.playerFactory,
    super.key,
    this.autoLoadVideo = false,
  });

  final String videoUrl;
  final String videoId;
  final OnPlayStateChanged onPlayStateChanged;
  final bool isActiveVideo;

  /// Factory to create the video player instance.
  /// The application decides which player to use for the current platform.
  final VideoPlayerFactory playerFactory;

  /// When true, automatically starts video playback without user tap.
  /// Used in mobile layout where the center item auto-plays.
  final bool autoLoadVideo;

  @override
  State<GalleryVideoPlayer> createState() => GalleryVideoPlayerState();
}

class GalleryVideoPlayerState extends State<GalleryVideoPlayer> {
  VideoPlayerInterface? player;
  bool isInitialized = false;
  bool isPlaying = false;
  bool isVisible = true;
  bool hasError = false;
  bool showInPlaceVideo = false;

  String get posterUrl => VideoUrlUtils.getPosterUrl(widget.videoUrl);

  @override
  void initState() {
    super.initState();
    if (widget.autoLoadVideo && widget.isActiveVideo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) handlePlayTap();
      });
    }
  }

  @override
  void didUpdateWidget(GalleryVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActiveVideo && showInPlaceVideo) {
      resetToPreview();
    }
    if (widget.autoLoadVideo &&
        widget.isActiveVideo &&
        !oldWidget.isActiveVideo &&
        !showInPlaceVideo) {
      handlePlayTap();
    }
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (showInPlaceVideo) {
      return VisibilityDetector(
        key: Key('video_${widget.videoId}'),
        onVisibilityChanged: handleVisibilityChanged,
        child: buildVideoContent(),
      );
    }

    return VisibilityDetector(
      key: Key('video_${widget.videoId}'),
      onVisibilityChanged: handleVisibilityChanged,
      child: ColoredBox(
        color: Colors.black,
        child: buildPosterWithPlayButton(),
      ),
    );
  }

  Widget buildPosterWithPlayButton() {
    return GestureDetector(
      onTap: handlePlayTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            posterUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stack) {
              return Container(
                color: Colors.grey[900],
                child: const Center(
                  child:
                      Icon(Icons.videocam_off, color: Colors.white38, size: 48),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void handlePlayTap() {
    setState(() {
      showInPlaceVideo = true;
    });
    unawaited(initializePlayer());
  }

  Future<void> initializePlayer() async {
    player = widget.playerFactory();

    if (mounted) setState(() {});

    await player!.initialize(
      onPlayingChanged: ({required isPlaying}) {
        if (mounted && isPlaying != this.isPlaying) {
          setState(() => this.isPlaying = isPlaying);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            hasError = true;
            showInPlaceVideo = false;
          });
        }
      },
    );

    try {
      await player!.open(widget.videoUrl);

      if (mounted) {
        setState(() => isInitialized = true);
        widget.onPlayStateChanged(widget.videoId, isPlaying: true);
      }
    } on Object {
      if (mounted) {
        setState(() {
          hasError = true;
          showInPlaceVideo = false;
        });
      }
    }
  }

  Widget buildVideoContent() {
    if (player == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return player!.buildVideoWidget(
      
    );
  }

  void handleVisibilityChanged(VisibilityInfo info) {
    final visible = info.visibleFraction > 0.5;
    if (visible != isVisible) {
      isVisible = visible;
      if (!isVisible && showInPlaceVideo) {
        resetToPreview();
      }
    }
  }

  void resetToPreview() {
    player?.dispose();
    player = null;
    setState(() {
      showInPlaceVideo = false;
      isInitialized = false;
      isPlaying = false;
      hasError = false;
    });
    widget.onPlayStateChanged(widget.videoId, isPlaying: false);
  }
}
