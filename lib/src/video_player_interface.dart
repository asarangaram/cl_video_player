import 'package:flutter/material.dart';

/// Callback for playing state changes.
typedef PlayingStateCallback = void Function(bool isPlaying);

/// Callback for position changes.
typedef PositionCallback = void Function(Duration position);

/// Callback for duration changes.
typedef DurationCallback = void Function(Duration duration);

/// Callback for errors.
typedef ErrorCallback = void Function(Object error);

/// Abstract interface for video player operations.
///
/// This interface abstracts the differences between video player packages
/// (media_kit, video_player, HTML5 video), allowing runtime switching
/// between implementations.
abstract interface class VideoPlayerInterface {
  /// Initialize the player with optional callbacks for state changes.
  ///
  /// Must be called before [open].
  Future<void> initialize({
    PlayingStateCallback? onPlayingChanged,
    PositionCallback? onPositionChanged,
    DurationCallback? onDurationChanged,
    ErrorCallback? onError,
  });

  /// Open and optionally start playing a video from the given URL.
  ///
  /// [url] can be a network URL or asset path.
  /// [autoPlay] if true, starts playing immediately after loading.
  Future<void> open(String url, {bool autoPlay = true});

  /// Start or resume playback.
  Future<void> play();

  /// Pause playback.
  Future<void> pause();

  /// Set volume level.
  ///
  /// [volume] is normalized to 0.0-1.0 range.
  Future<void> setVolume(double volume);

  /// Seek to a specific position.
  Future<void> seekTo(Duration position);

  /// Set looping mode.
  Future<void> setLooping(bool loop);

  /// Current playing state.
  bool get isPlaying;

  /// Current playback position.
  Duration get position;

  /// Total video duration.
  Duration get duration;

  /// Whether the player is initialized and ready.
  bool get isInitialized;

  /// Whether an error occurred.
  bool get hasError;

  /// Build the video widget for display.
  ///
  /// [fit] controls how the video is inscribed into its container.
  /// [showControls] whether to show built-in controls.
  Widget buildVideoWidget({
    BoxFit fit = BoxFit.contain,
    bool showControls = false,
  });

  /// Dispose of player resources.
  ///
  /// Must be called when the player is no longer needed.
  void dispose();
}
