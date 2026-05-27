import 'package:flutter/material.dart';

import 'video_player_interface.dart';

/// Stub for [OverlayVideoPlayer] on non-web platforms.
///
/// Web-only — throws [UnsupportedError] if used outside a browser.
class OverlayVideoPlayer implements VideoPlayerInterface {
  @override
  Future<void> initialize({
    PlayingStateCallback? onPlayingChanged,
    PositionCallback? onPositionChanged,
    DurationCallback? onDurationChanged,
    ErrorCallback? onError,
  }) async {
    throw UnsupportedError('OverlayVideoPlayer is only available on web.');
  }

  @override
  Future<void> open(String url, {bool autoPlay = true}) async {
    throw UnsupportedError('OverlayVideoPlayer is only available on web.');
  }

  @override
  Future<void> play() async {
    throw UnsupportedError('OverlayVideoPlayer is only available on web.');
  }

  @override
  Future<void> pause() async {
    throw UnsupportedError('OverlayVideoPlayer is only available on web.');
  }

  @override
  Future<void> setVolume(double volume) async {
    throw UnsupportedError('OverlayVideoPlayer is only available on web.');
  }

  @override
  Future<void> seekTo(Duration position) async {
    throw UnsupportedError('OverlayVideoPlayer is only available on web.');
  }

  @override
  Future<void> setLooping({required bool loop}) async {
    throw UnsupportedError('OverlayVideoPlayer is only available on web.');
  }

  @override
  bool get isPlaying => false;

  @override
  Duration get position => Duration.zero;

  @override
  Duration get duration => Duration.zero;

  @override
  bool get isInitialized => false;

  @override
  bool get hasError => true;

  @override
  Widget buildVideoWidget({
    BoxFit fit = BoxFit.contain,
    bool showControls = false,
  }) => const SizedBox.shrink();

  @override
  void dispose() {}

  /// Stub — no-op on non-web platforms.
  void updatePosition(Rect rect) {}

  /// Stub — no-op on non-web platforms.
  void startPositionSync(GlobalKey key) {}
}

/// Stub placeholder widget for non-web platforms.
class OverlayVideoPlaceholder extends StatelessWidget {
  const OverlayVideoPlaceholder({
    required this.player,
    required this.onPositionChanged,
    super.key,
  });

  final OverlayVideoPlayer player;
  final void Function(Rect rect) onPositionChanged;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
