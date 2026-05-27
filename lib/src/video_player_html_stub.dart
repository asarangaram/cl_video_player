import 'package:flutter/material.dart';

import 'video_player_interface.dart';

/// Stub for [HtmlVideoPlayer] on non-web platforms.
///
/// Web-only — throws [UnsupportedError] if used outside a browser.
class HtmlVideoPlayer implements VideoPlayerInterface {
  @override
  Future<void> initialize({
    PlayingStateCallback? onPlayingChanged,
    PositionCallback? onPositionChanged,
    DurationCallback? onDurationChanged,
    ErrorCallback? onError,
  }) async {
    throw UnsupportedError('HtmlVideoPlayer is only available on web.');
  }

  @override
  Future<void> open(String url, {bool autoPlay = true}) async {
    throw UnsupportedError('HtmlVideoPlayer is only available on web.');
  }

  @override
  Future<void> play() async {
    throw UnsupportedError('HtmlVideoPlayer is only available on web.');
  }

  @override
  Future<void> pause() async {
    throw UnsupportedError('HtmlVideoPlayer is only available on web.');
  }

  @override
  Future<void> setVolume(double volume) async {
    throw UnsupportedError('HtmlVideoPlayer is only available on web.');
  }

  @override
  Future<void> seekTo(Duration position) async {
    throw UnsupportedError('HtmlVideoPlayer is only available on web.');
  }

  @override
  Future<void> setLooping({required bool loop}) async {
    throw UnsupportedError('HtmlVideoPlayer is only available on web.');
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
}
