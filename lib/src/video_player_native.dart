import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_player_interface.dart';

/// video_player package implementation of [VideoPlayerInterface].
///
/// Uses Flutter's official video_player package.
/// Works on all platforms (iOS, Android, Web, Desktop).
///
/// Includes Safari compatibility option:
/// - Set [applySafariFirstFrameFix] to true to append #t=0.001 to URLs
/// - This forces Safari to seek and render the first frame
class NativeVideoPlayer implements VideoPlayerInterface {

  NativeVideoPlayer({this.applySafariFirstFrameFix = false});
  VideoPlayerController? _controller;

  bool _hasError = false;
  PlayingStateCallback? _onPlayingChanged;
  PositionCallback? _onPositionChanged;
  DurationCallback? _onDurationChanged;
  ErrorCallback? _onError;

  bool _lastPlayingState = false;
  Duration _lastPosition = Duration.zero;

  /// Whether to apply Safari first-frame fix by appending #t=0.001 to URLs.
  /// Set this to true when running on Safari/WebKit browsers.
  final bool applySafariFirstFrameFix;

  @override
  Future<void> initialize({
    PlayingStateCallback? onPlayingChanged,
    PositionCallback? onPositionChanged,
    DurationCallback? onDurationChanged,
    ErrorCallback? onError,
  }) async {
    _onPlayingChanged = onPlayingChanged;
    _onPositionChanged = onPositionChanged;
    _onDurationChanged = onDurationChanged;
    _onError = onError;
  }

  @override
  Future<void> open(String url, {bool autoPlay = true}) async {
    await _controller?.dispose();

    try {
      final compatibleUrl = _getCompatibleUrl(url);
      _controller = VideoPlayerController.networkUrl(Uri.parse(compatibleUrl));

      _controller!.addListener(_onControllerUpdate);

      await _controller!.initialize();

      // Notify duration once initialized
      _onDurationChanged?.call(_controller!.value.duration);

      if (autoPlay) {
        await _controller!.play();
      }

      _hasError = false;
    } catch (e) {
      _hasError = true;
      _onError?.call(e);
      rethrow;
    }
  }

  /// Returns a Safari-compatible URL if [applySafariFirstFrameFix] is enabled.
  ///
  /// Safari has a bug where the first frame often doesn't load.
  /// Appending #t=0.001 forces the browser to seek and render the first frame.
  String _getCompatibleUrl(String url) {
    if (applySafariFirstFrameFix && !url.contains('#t=')) {
      return '$url#t=0.001';
    }
    return url;
  }

  void _onControllerUpdate() {
    if (_controller == null) return;

    final value = _controller!.value;

    // Notify playing state changes (only when changed)
    if (value.isPlaying != _lastPlayingState) {
      _lastPlayingState = value.isPlaying;
      _onPlayingChanged?.call(isPlaying: value.isPlaying);
    }

    // Notify position changes (throttled to avoid excessive updates)
    if ((value.position - _lastPosition).abs() >
        const Duration(milliseconds: 100)) {
      _lastPosition = value.position;
      _onPositionChanged?.call(value.position);
    }

    // Handle errors
    if (value.hasError && !_hasError) {
      _hasError = true;
      _onError?.call(value.errorDescription ?? 'Unknown video error');
    }
  }

  @override
  Future<void> play() async => _controller?.play();

  @override
  Future<void> pause() async => _controller?.pause();

  @override
  Future<void> setVolume(double volume) async {
    // video_player uses 0.0-1.0 scale (same as interface)
    await _controller?.setVolume(volume);
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> setLooping({required bool loop}) async {
    await _controller?.setLooping(loop);
  }

  @override
  bool get isPlaying => _controller?.value.isPlaying ?? false;

  @override
  Duration get position => _controller?.value.position ?? Duration.zero;

  @override
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  bool get hasError => _hasError || (_controller?.value.hasError ?? false);

  @override
  Widget buildVideoWidget({
    BoxFit fit = BoxFit.contain,
    bool showControls = false,
  }) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    // video_player requires AspectRatio wrapper
    Widget videoWidget = AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );

    // Apply fit using FittedBox for non-contain fits
    if (fit != BoxFit.contain) {
      videoWidget = FittedBox(
        fit: fit,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }

    return videoWidget;
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    unawaited(_controller?.dispose());
    _controller = null;
  }
}
