import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'video_player_interface.dart';

/// media_kit implementation of [VideoPlayerInterface].
///
/// Uses texture-based rendering which provides:
/// - Proper compositing with Flutter widgets
/// - Working AnimatedSwitcher crossfades
/// - Correct z-ordering with overlays
///
/// Best for desktop and Android platforms.
/// Requires MediaKit.ensureInitialized() to be called at app startup.
class MediaKitVideoPlayer implements VideoPlayerInterface {
  Player? _player;
  VideoController? _controller;

  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  Future<void> initialize({
    PlayingStateCallback? onPlayingChanged,
    PositionCallback? onPositionChanged,
    DurationCallback? onDurationChanged,
    ErrorCallback? onError,
  }) async {
    _player = Player(
      
    );
    _controller = VideoController(_player!);

    _subscriptions
      ..add(_player!.stream.playing.listen((playing) {
        _isPlaying = playing;
        onPlayingChanged?.call(isPlaying: playing);
      }))
      ..add(_player!.stream.position.listen((pos) {
        _position = pos;
        onPositionChanged?.call(pos);
      }))
      ..add(_player!.stream.duration.listen((dur) {
        _duration = dur;
        onDurationChanged?.call(dur);
      }))
      ..add(_player!.stream.error.listen((error) {
        _hasError = true;
        onError?.call(error);
      }));
  }

  @override
  Future<void> open(String url, {bool autoPlay = true}) async {
    try {
      final media = Media(url);
      await _player!.open(media, play: autoPlay);
      _isInitialized = true;
      _hasError = false;
    } on Object {
      _hasError = true;
      rethrow;
    }
  }

  @override
  Future<void> play() async => _player?.play();

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> setVolume(double volume) async {
    // media_kit uses 0-100 scale, interface uses 0.0-1.0
    await _player?.setVolume(volume * 100);
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _player?.seek(position);
  }

  @override
  Future<void> setLooping({required bool loop}) async {
    await _player?.setPlaylistMode(
      loop ? PlaylistMode.single : PlaylistMode.none,
    );
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get hasError => _hasError;

  @override
  Widget buildVideoWidget({
    BoxFit fit = BoxFit.contain,
    bool showControls = false,
  }) {
    if (_controller == null) {
      return const SizedBox.shrink();
    }
    return Video(
      controller: _controller!,
      fit: fit,
      controls: showControls ? AdaptiveVideoControls : null,
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    unawaited(_player?.dispose());
    _player = null;
    _controller = null;
  }
}
