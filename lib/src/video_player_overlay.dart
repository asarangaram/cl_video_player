import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'video_player_interface.dart';

/// Debug logging for video player
void _log(String message) {
  if (kDebugMode) {
    print('[OverlayVideoPlayer] $message');
  }
  web.console.log('[OverlayVideoPlayer] $message'.toJS);
}

/// Video player that renders outside Flutter's widget tree.
///
/// This bypasses Flutter's platform view system (which has positioning bugs
/// on Safari) by creating the video element directly in the DOM and
/// positioning it absolutely to overlay the Flutter canvas.
///
/// Web-only, best for Safari compatibility.
/// Bypasses Flutter's platform view positioning bugs.
class OverlayVideoPlayer implements VideoPlayerInterface {
  web.HTMLVideoElement? _videoElement;
  web.HTMLDivElement? _containerElement;
  String? _containerId;

  bool _isInitialized = false;
  bool _hasError = false;
  bool _lastPlayingState = false;

  PlayingStateCallback? _onPlayingChanged;
  PositionCallback? _onPositionChanged;
  DurationCallback? _onDurationChanged;
  ErrorCallback? _onError;

  Timer? _positionTimer;

  // For position syncing
  GlobalKey? _widgetKey;
  Timer? _positionSyncTimer;

  static int _instanceCounter = 0;

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
    _log('open() called with url: $url');
    dispose();

    try {
      _containerId = 'overlay-video-${_instanceCounter++}';

      // Create container div with fixed position
      // Position updates every frame via _OverlayVideoPlaceholder, so it
      // scrolls correctly
      _containerElement = web.HTMLDivElement()
        ..id = _containerId!
        ..style.position = 'fixed'
        ..style.zIndex = '1000'
        ..style.pointerEvents = 'none' // Let clicks pass through to Flutter
        ..style.overflow = 'hidden'
        ..style.backgroundColor = 'black';

      // Create video element inside container
      _videoElement = web.HTMLVideoElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.pointerEvents = 'auto' // Video itself captures clicks
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true')
        ..setAttribute('x-webkit-airplay', 'allow')
        // Show native controls for manual play
        ..setAttribute('controls', 'true')
        ..setAttribute('preload', 'auto') // Start loading immediately
        ..setAttribute('crossorigin', 'anonymous') // Required for CORS
        ..muted = true // Muted for autoplay compliance on Safari
        ..src = url;

      _containerElement!.appendChild(_videoElement!);

      // Append to body (outside Flutter)
      web.document.body!.appendChild(_containerElement!);
      _log('Container appended to body with id: $_containerId');

      _setupEventListeners();

      await _waitForLoad();

      _isInitialized = true;
      _hasError = false;

      _startPositionTracking();

      if (autoPlay) {
        await play();
      }
    } on Object catch (e) {
      _log('ERROR in open(): $e');
      _hasError = true;
      _onError?.call(e);
      rethrow;
    }
  }

  void _setupEventListeners() {
    final video = _videoElement;
    if (video == null) return;

    video
      ..addEventListener(
          'play',
          ((web.Event event) {
            _log('EVENT: play');
            if (!_lastPlayingState) {
              _lastPlayingState = true;
              _onPlayingChanged?.call(isPlaying: true);
            }
          }).toJS)
      ..addEventListener(
          'pause',
          ((web.Event event) {
            _log('EVENT: pause');
            if (_lastPlayingState) {
              _lastPlayingState = false;
              _onPlayingChanged?.call(isPlaying: false);
            }
          }).toJS)
      ..addEventListener(
          'playing',
          ((web.Event event) {
            _log('EVENT: playing');
          }).toJS)
      ..addEventListener(
          'loadedmetadata',
          ((web.Event event) {
            _log(
              'EVENT: loadedmetadata - '
              '${video.videoWidth}x${video.videoHeight}',
            );
          }).toJS)
      ..addEventListener(
          'durationchange',
          ((web.Event event) {
            final dur = video.duration;
            if (!dur.isNaN && dur.isFinite) {
              _onDurationChanged
                  ?.call(Duration(milliseconds: (dur * 1000).toInt()));
            }
          }).toJS)
      ..addEventListener(
          'error',
          ((web.Event event) {
            final error = video.error;
            _log('EVENT: error - ${error?.message}');
            _hasError = true;
            _onError?.call('Video error: ${error?.message}');
          }).toJS);
  }

  Future<void> _waitForLoad() async {
    final video = _videoElement;
    if (video == null) return;

    final completer = Completer<void>();

    video
      ..addEventListener(
          'canplay',
          ((web.Event event) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          }).toJS)
      ..addEventListener(
          'error',
          ((web.Event event) {
            if (!completer.isCompleted) {
              completer.completeError('Failed to load video');
            }
          }).toJS)
      ..load();

    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('Video load timeout'),
    );
  }

  void _startPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final video = _videoElement;
      if (video != null && !video.currentTime.isNaN) {
        _onPositionChanged?.call(
          Duration(milliseconds: (video.currentTime * 1000).toInt()),
        );
      }
    });
  }

  /// Update the overlay position to match a Flutter widget's position.
  /// Call this from the widget's build method.
  void updatePosition(Rect rect) {
    final container = _containerElement;
    if (container == null) return;

    // Hide if scrolled out of viewport
    final viewportWidth = web.window.innerWidth;
    final viewportHeight = web.window.innerHeight;

    final isVisible = rect.right > 0 &&
        rect.bottom > 0 &&
        rect.left < viewportWidth &&
        rect.top < viewportHeight;

    if (isVisible) {
      container.style.display = 'block';
      container.style.left = '${rect.left}px';
      container.style.top = '${rect.top}px';
      container.style.width = '${rect.width}px';
      container.style.height = '${rect.height}px';
    } else {
      container.style.display = 'none';
    }
  }

  /// Start syncing position with a GlobalKey's render box.
  void startPositionSync(GlobalKey key) {
    _widgetKey = key;
    _positionSyncTimer?.cancel();
    _positionSyncTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _syncPosition();
    });
    // Initial sync
    _syncPosition();
  }

  void _syncPosition() {
    final key = _widgetKey;
    if (key == null) return;

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    updatePosition(Rect.fromLTWH(
      position.dx,
      position.dy,
      size.width,
      size.height,
    ));
  }

  @override
  Future<void> play() async {
    _log('play() called');
    final video = _videoElement;
    if (video == null) return;

    // Safari requires muted for autoplay
    video.muted = true;

    try {
      await video.play().toDart;
      _log('play() succeeded (muted)');

      // Try to unmute after a short delay
      unawaited(Future.delayed(const Duration(milliseconds: 500), () {
        if (!video.paused) {
          _log('Attempting to unmute...');
          video.muted = false;
        }
      }));
    } on Object catch (e) {
      _log('play() failed even muted: $e');
    }
  }

  @override
  Future<void> pause() async {
    _videoElement?.pause();
  }

  @override
  Future<void> setVolume(double volume) async {
    final video = _videoElement;
    if (video != null) {
      video
        ..volume = volume
        ..muted = volume == 0;
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    final video = _videoElement;
    if (video != null) {
      video.currentTime = position.inMilliseconds / 1000.0;
    }
  }

  @override
  Future<void> setLooping({required bool loop}) async {
    _videoElement?.loop = loop;
  }

  @override
  bool get isPlaying => _lastPlayingState;

  @override
  Duration get position {
    final time = _videoElement?.currentTime ?? 0;
    return Duration(milliseconds: (time * 1000).toInt());
  }

  @override
  Duration get duration {
    final dur = _videoElement?.duration ?? 0;
    if (dur.isNaN || !dur.isFinite) return Duration.zero;
    return Duration(milliseconds: (dur * 1000).toInt());
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get hasError => _hasError;

  @override
  Widget buildVideoWidget({
    BoxFit fit = BoxFit.contain,
    bool showControls = false,
  }) {
    // Update object-fit
    final objectFit = switch (fit) {
      BoxFit.contain => 'contain',
      BoxFit.cover => 'cover',
      BoxFit.fill => 'fill',
      _ => 'contain',
    };
    _videoElement?.style.objectFit = objectFit;

    // Return a placeholder that we use to track position
    return OverlayVideoPlaceholder(
      player: this,
      onPositionChanged: updatePosition,
    );
  }

  @override
  void dispose() {
    _log('dispose() called');
    _positionTimer?.cancel();
    _positionSyncTimer?.cancel();

    _videoElement?.pause();
    _containerElement?.remove();

    _videoElement = null;
    _containerElement = null;
    _isInitialized = false;
    _hasError = false;
    _lastPlayingState = false;
  }
}

/// Placeholder widget that tracks its position and updates the overlay video.
class OverlayVideoPlaceholder extends StatefulWidget {
  const OverlayVideoPlaceholder({
    required this.player, required this.onPositionChanged, super.key,
  });

  final OverlayVideoPlayer player;
  final void Function(Rect rect) onPositionChanged;

  @override
  State<OverlayVideoPlaceholder> createState() =>
      OverlayVideoPlaceholderState();
}

class OverlayVideoPlaceholderState extends State<OverlayVideoPlaceholder> {
  final GlobalKey _key = GlobalKey();
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    // Start position sync after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePosition();
      // Sync frequently for smooth scrolling (60fps)
      _syncTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        _updatePosition();
      });
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _updatePosition() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    widget.onPositionChanged(Rect.fromLTWH(
      position.dx,
      position.dy,
      size.width,
      size.height,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Transparent placeholder that occupies space
    return SizedBox.expand(
      key: _key,
      child: const ColoredBox(color: Colors.transparent),
    );
  }
}
