import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'video_player_interface.dart';

/// Debug logging for video player
void _log(String message) {
  if (kDebugMode) {
    print('[HtmlVideoPlayer] $message');
  }
  web.console.log('[HtmlVideoPlayer] $message'.toJS);
}

/// HTML5 video player implementation using native browser `<video>` element.
///
/// This bypasses Flutter's texture/canvas rendering entirely and embeds
/// the browser's native video player via HtmlElementView.
///
/// Benefits:
/// - Native browser video playback (no WebGL/canvas issues)
/// - Better Safari compatibility
/// - Hardware acceleration handled by browser
///
/// Web-only implementation.
class HtmlVideoPlayer implements VideoPlayerInterface {
  web.HTMLVideoElement? _videoElement;
  String? _viewType;
  bool _isInitialized = false;
  bool _hasError = false;

  PlayingStateCallback? _onPlayingChanged;
  PositionCallback? _onPositionChanged;
  DurationCallback? _onDurationChanged;
  ErrorCallback? _onError;

  Timer? _positionTimer;
  bool _lastPlayingState = false;

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
    _log('open() called with url: $url, autoPlay: $autoPlay');
    dispose();

    try {
      // Create unique view type for this instance
      _viewType = 'html-video-player-${_instanceCounter++}';
      _log('Created viewType: $_viewType');

      // Create the video element
      _videoElement = web.HTMLVideoElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.backgroundColor = 'transparent'
        ..style.display = 'block'
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true')
        ..setAttribute('x-webkit-airplay', 'allow')
        ..setAttribute('autoplay', autoPlay ? 'true' : 'false')
        ..src = url;

      _log('Video element created, src set');

      // Register the platform view factory
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType!,
        (int viewId) {
          _log('Platform view factory called with viewId: $viewId');
          _logVideoState();

          // Fix parent sizing after a short delay (once element is in DOM)
          unawaited(Future.delayed(
            const Duration(milliseconds: 100),
            _fixPlatformViewSizing,
          ));

          return _videoElement!;
        },
      );
      _log('Platform view factory registered');

      // Set up event listeners
      _setupEventListeners();

      // Wait for video to be ready
      _log('Waiting for video to load...');
      await _waitForLoad();
      _log('Video loaded successfully');

      _isInitialized = true;
      _hasError = false;

      // Log video properties after load
      _logVideoState();

      // Start position tracking
      _startPositionTracking();

      if (autoPlay) {
        _log('Starting autoplay...');
        await play();
      }
    } on Object catch (e) {
      _log('ERROR in open(): $e');
      _hasError = true;
      _onError?.call(e);
      rethrow;
    }
  }

  void _logVideoState() {
    final video = _videoElement;
    if (video == null) {
      _log('Video element is NULL');
      return;
    }
    _log('Video state:');
    _log('  - readyState: ${video.readyState}');
    _log('  - networkState: ${video.networkState}');
    _log('  - videoWidth: ${video.videoWidth}');
    _log('  - videoHeight: ${video.videoHeight}');
    _log('  - duration: ${video.duration}');
    _log('  - paused: ${video.paused}');
    _log('  - muted: ${video.muted}');
    _log('  - currentSrc: ${video.currentSrc}');
    _log('  - style.width: ${video.style.width}');
    _log('  - style.height: ${video.style.height}');
    _log('  - style.display: ${video.style.display}');
    _log('  - style.visibility: ${video.style.visibility}');
    _log('  - style.opacity: ${video.style.opacity}');

    // Check if video is in DOM
    final parent = video.parentElement;
    _log('  - parentElement: ${parent?.tagName ?? "NO PARENT"}');

    // Get computed dimensions
    final rect = video.getBoundingClientRect();
    _log(
      '  - boundingRect: ${rect.width}x${rect.height} '
      'at (${rect.left}, ${rect.top})',
    );
  }

  void _setupEventListeners() {
    final video = _videoElement;
    if (video == null) return;

    _log('Setting up event listeners...');

    video
      ..addEventListener(
        'play',
        ((web.Event event) {
          _log('EVENT: play');
          if (!_lastPlayingState) {
            _lastPlayingState = true;
            _onPlayingChanged?.call(isPlaying: true);
          }
        }).toJS,
      )
      ..addEventListener(
        'pause',
        ((web.Event event) {
          _log('EVENT: pause');
          if (_lastPlayingState) {
            _lastPlayingState = false;
            _onPlayingChanged?.call(isPlaying: false);
          }
        }).toJS,
      )
      ..addEventListener(
        'playing',
        ((web.Event event) {
          _log('EVENT: playing (video frames are rendering)');
          _logVideoState();
        }).toJS,
      )
      ..addEventListener(
        'loadedmetadata',
        ((web.Event event) {
          _log('EVENT: loadedmetadata');
          _logVideoState();
        }).toJS,
      )
      ..addEventListener(
        'loadeddata',
        ((web.Event event) {
          _log('EVENT: loadeddata (first frame available)');
          _logVideoState();
        }).toJS,
      )
      ..addEventListener(
        'durationchange',
        ((web.Event event) {
          _log('EVENT: durationchange - ${video.duration}');
          final dur = video.duration;
          if (!dur.isNaN && dur.isFinite) {
            _onDurationChanged
                ?.call(Duration(milliseconds: (dur * 1000).toInt()));
          }
        }).toJS,
      )
      ..addEventListener(
        'error',
        ((web.Event event) {
          final error = video.error;
          _log(
            'EVENT: error - code: ${error?.code}, '
            'message: ${error?.message}',
          );
          _hasError = true;
          _onError?.call('Video playback error: ${error?.message}');
        }).toJS,
      )
      ..addEventListener(
        'stalled',
        ((web.Event event) {
          _log('EVENT: stalled (buffering)');
        }).toJS,
      )
      ..addEventListener(
        'waiting',
        ((web.Event event) {
          _log('EVENT: waiting (buffering)');
        }).toJS,
      );
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
        }).toJS,
      )
      ..addEventListener(
        'error',
        ((web.Event event) {
          if (!completer.isCompleted) {
            completer.completeError('Failed to load video');
          }
        }).toJS,
      )
      ..load();

    // Timeout after 30 seconds
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Video load timeout');
      },
    );
  }

  void _startPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      final video = _videoElement;
      if (video != null && !video.currentTime.isNaN) {
        _onPositionChanged?.call(
          Duration(milliseconds: (video.currentTime * 1000).toInt()),
        );

        // Log state every 5 seconds during playback
        if (timer.tick % 20 == 0) {
          _log(
            'Periodic state check '
            '(${video.currentTime.toStringAsFixed(1)}s):',
          );
          _logVideoState();
          _inspectDomPlacement();
        }
      }
    });
  }

  void _fixPlatformViewSizing() {
    final video = _videoElement;
    if (video == null) return;

    final parent = video.parentElement;
    if (parent != null && parent.isA<web.HTMLElement>()) {
      final parentEl = parent as web.HTMLElement;
      _log('Fixing parent element sizing...');
      // Fix the flt-platform-view styling
      parentEl.style
        ..display = 'block'
        ..width = '100%'
        ..height = '100%';
      _log('Parent style fixed: display=block, width=100%, height=100%');

      // Also check grandparent
      final grandparent = parentEl.parentElement;
      if (grandparent != null && grandparent.isA<web.HTMLElement>()) {
        (grandparent as web.HTMLElement).style
          ..display = 'block'
          ..width = '100%'
          ..height = '100%';
        _log('Grandparent style fixed');
      }
    }
  }

  void _inspectDomPlacement() {
    final video = _videoElement;
    if (video == null) return;

    // Walk up the DOM tree to see where video is placed
    var current = video as web.Element?;
    var depth = 0;
    final path = <String>[];

    while (current != null && depth < 10) {
      final tag = current.tagName;
      final id = current.id;
      final classes = current.className;
      path.add(
        '$tag'
        '${id.isNotEmpty ? "#$id" : ""}'
        '${classes.isNotEmpty ? ".$classes" : ""}',
      );
      current = current.parentElement;
      depth++;
    }

    _log('DOM path: ${path.join(" > ")}');

    // Check for flt-glass-pane and platform view containers
    final glassPanes = web.document.querySelectorAll('flt-glass-pane');
    _log('Found ${glassPanes.length} flt-glass-pane elements');

    final platformViews = web.document.querySelectorAll('flt-platform-view');
    _log('Found ${platformViews.length} flt-platform-view elements');

    // Check z-index of video's container
    final parent = video.parentElement;
    if (parent != null) {
      final computedStyle = web.window.getComputedStyle(parent);
      _log('Parent zIndex: ${computedStyle.zIndex}');
      _log('Parent position: ${computedStyle.position}');
      _log('Parent visibility: ${computedStyle.visibility}');
      _log('Parent opacity: ${computedStyle.opacity}');
    }
  }

  @override
  Future<void> play() async {
    _log('play() called');
    try {
      await _videoElement?.play().toDart;
      _log('play() succeeded');
      _logVideoState();
    } on Object catch (e) {
      _log('play() failed: $e - trying muted');
      // Autoplay might be blocked, try muted
      _videoElement?.muted = true;
      await _videoElement?.play().toDart;
      _log('play() muted succeeded');
      _logVideoState();
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
    _log(
      'buildVideoWidget() called - viewType: $_viewType, '
      'videoElement: ${_videoElement != null}',
    );

    if (_viewType == null || _videoElement == null) {
      _log(
        'buildVideoWidget() returning SizedBox.shrink '
        '(no viewType or videoElement)',
      );
      return const SizedBox.shrink();
    }

    // Update object-fit based on BoxFit
    final objectFit = switch (fit) {
      BoxFit.contain => 'contain',
      BoxFit.cover => 'cover',
      BoxFit.fill => 'fill',
      BoxFit.fitWidth => 'cover',
      BoxFit.fitHeight => 'cover',
      BoxFit.none => 'none',
      BoxFit.scaleDown => 'scale-down',
    };
    _videoElement!.style.objectFit = objectFit;

    _log(
      'buildVideoWidget() returning HtmlElementView with '
      'viewType: $_viewType',
    );
    _logVideoState();

    // Wrap in SizedBox.expand to ensure Flutter gives it proper dimensions
    // Without this, flt-platform-view gets display:inline and collapses
    return SizedBox.expand(
      child: HtmlElementView(viewType: _viewType!),
    );
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _positionTimer = null;

    _videoElement?.pause();
    _videoElement?.src = '';
    _videoElement = null;
    _viewType = null;

    _isInitialized = false;
    _hasError = false;
    _lastPlayingState = false;
  }
}
