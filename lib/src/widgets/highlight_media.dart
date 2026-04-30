import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../providers/media_control.dart';
import '../video_player_interface.dart';
import '../video_url_utils.dart';
import '../gallery_video_player.dart' show VideoPlayerFactory;
import 'highlight_image.dart';

/// Platform-agnostic media renderer for video or image content.
///
/// Accepts a URL that is either a video or an image (webp/png/jpg etc).
/// - For images: displays via [HighlightImage], pauses animation via TickerMode
/// - For videos: creates a player via [playerFactory], plays inline
///
/// Listens to [mediaControlProvider] for mute and play/pause control.
/// This allows both direct taps (in standalone usage) and external
/// toggles (when layered under other widgets) to control playback.
///
/// Automatically pauses video when scrolled offscreen and resumes
/// when visible again (respecting user pause state).
///
/// This widget does NOT detect platform or browser. The caller decides
/// what URL and factory to pass based on platform context.
class HighlightMedia extends ConsumerStatefulWidget {
  const HighlightMedia({
    super.key,
    required this.url,
    this.playerFactory,
    this.fit = BoxFit.cover,
  });

  /// The media URL — either a video URL or an image URL.
  final String url;

  /// Factory to create a video player. Required when [url] is a video.
  /// Ignored when [url] is an image.
  final VideoPlayerFactory? playerFactory;

  /// How to fit the media in its container.
  final BoxFit fit;

  @override
  ConsumerState<HighlightMedia> createState() => HighlightMediaState();
}

class HighlightMediaState extends ConsumerState<HighlightMedia> {
  VideoPlayerInterface? player;
  bool isVideoInitialized = false;
  bool hasError = false;
  bool isVisible = true;

  bool get isVideo => VideoUrlUtils.isVideoUrl(widget.url);
  bool get isAnimatedWebp => VideoUrlUtils.isAnimatedWebpUrl(widget.url);

  @override
  void initState() {
    super.initState();
    if (isVideo && widget.playerFactory != null) {
      initializeVideoPlayer();
    }
  }

  @override
  void didUpdateWidget(HighlightMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      if (player != null) {
        disposePlayer();
      }
      if (isVideo && widget.playerFactory != null) {
        initializeVideoPlayer();
      }
    }
  }

  @override
  void dispose() {
    disposePlayer();
    super.dispose();
  }

  Future<void> initializeVideoPlayer() async {
    player = widget.playerFactory!();

    try {
      await player!.initialize(
        onError: (error) {
          if (mounted) {
            setState(() => hasError = true);
          }
        },
      );

      await player!.setLooping(true);

      if (!mounted) return;

      // Apply current media control state
      final control = ref.read(mediaControlProvider);
      await player!.setVolume(control.isMuted ? 0.0 : 1.0);

      await player!.open(widget.url, autoPlay: !control.isPaused && isVisible);

      if (mounted) {
        setState(() => isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('HighlightMedia: Video initialization failed: $e');
      if (mounted) {
        setState(() => hasError = true);
      }
    }
  }

  void disposePlayer() {
    player?.dispose();
    player = null;
    isVideoInitialized = false;
    hasError = false;
  }

  void togglePlaybackPaused() {
    ref.read(mediaControlProvider.notifier).togglePause();
  }

  void handleVisibilityChanged(VisibilityInfo info) {
    final nowVisible = info.visibleFraction > 0.1;
    if (nowVisible == isVisible) return;
    isVisible = nowVisible;

    if (player == null || !isVideoInitialized) return;

    final isPaused = ref.read(mediaControlProvider).isPaused;
    if (!isVisible) {
      // Scrolled offscreen — pause regardless of user state
      player!.pause();
    } else if (!isPaused) {
      // Back onscreen and user hasn't paused — resume
      player!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaControl = ref.watch(mediaControlProvider);

    // React to media control changes
    ref.listen<MediaControlState>(mediaControlProvider, (previous, current) {
      if (previous?.isMuted != current.isMuted) {
        player?.setVolume(current.isMuted ? 0.0 : 1.0);
      }
      if (previous?.isPaused != current.isPaused) {
        if (player == null || !isVideoInitialized) return;
        if (current.isPaused || !isVisible) {
          player!.pause();
        } else {
          player!.play();
        }
      }
    });

    if (!isVideo) {
      // Static images (jpg, png, etc.) — no pause/play, no overlay
      if (!isAnimatedWebp) {
        return HighlightImage(uri: widget.url, fit: widget.fit);
      }

      // Animated webp — supports pause/play with TickerMode
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: togglePlaybackPaused,
        child: TickerMode(
          enabled: !mediaControl.isPaused,
          child: HighlightImage(uri: widget.url, fit: widget.fit),
        ),
      );
    }

    if (hasError) {
      return buildErrorWidget(context);
    }

    if (!isVideoInitialized || player == null) {
      return buildLoadingWidget(context);
    }

    return VisibilityDetector(
      key: Key('highlight_media_${widget.url}'),
      onVisibilityChanged: handleVisibilityChanged,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: togglePlaybackPaused,
        child: player!.buildVideoWidget(fit: widget.fit, showControls: false),
      ),
    );
  }

  Widget buildLoadingWidget(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      color: theme.colorScheme.muted,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget buildErrorWidget(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      color: theme.colorScheme.muted,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load video',
              style: TextStyle(color: theme.colorScheme.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
