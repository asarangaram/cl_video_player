import 'dart:async';

import 'package:cl_gallery_viewer/cl_gallery_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:visibility_detector/visibility_detector.dart';

const _headers = {'Authorization': 'Bearer test-token'};

const _imageUrl = 'https://media.example.com/photo.jpg';
const _videoUrl = 'https://media.example.com/clip.mp4';
const _videoPoster = 'https://media.example.com/clip.jpg';
const _pdfUrl = 'https://media.example.com/doc.pdf';
const _pdfPreview = 'https://media.example.com/doc.png';

final _items = [
  GalleryItem.image(_imageUrl, previewUrl: null),
  GalleryItem.video(_videoUrl, previewUrl: _videoPoster),
  GalleryItem.pdf(_pdfUrl, previewUrl: _pdfPreview),
];

/// Records what the gallery asks of its video player.
class FakeVideoPlayer implements VideoPlayerInterface {
  final List<String> openedUrls = [];
  final List<Map<String, String>> openedHeaders = [];

  @override
  Future<void> initialize({
    PlayingStateCallback? onPlayingChanged,
    PositionCallback? onPositionChanged,
    DurationCallback? onDurationChanged,
    ErrorCallback? onError,
  }) async {}

  @override
  Future<void> open(
    String url, {
    bool autoPlay = true,
    Map<String, String> httpHeaders = const {},
  }) async {
    openedUrls.add(url);
    openedHeaders.add(httpHeaders);
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> setLooping({required bool loop}) async {}

  @override
  bool get isPlaying => false;

  @override
  Duration get position => Duration.zero;

  @override
  Duration get duration => Duration.zero;

  @override
  bool get isInitialized => true;

  @override
  bool get hasError => false;

  @override
  Widget buildVideoWidget({
    BoxFit fit = BoxFit.contain,
    bool showControls = false,
  }) => const SizedBox.expand();

  @override
  void dispose() {}
}

/// Records the data sources the `video_player` plugin is asked to create.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final List<DataSource> dataSources = [];
  final _events = <int, StreamController<VideoEvent>>{};
  int _nextId = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    dataSources.add(options.dataSource);
    final id = _nextId++;
    final events = StreamController<VideoEvent>();
    _events[id] = events;
    events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 1),
        size: const Size(16, 9),
      ),
    );
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async {
    await _events.remove(playerId)?.close();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

Widget host(Widget child) => ProviderScope(
  child: ShadApp(
    home: Scaffold(body: child),
  ),
);

/// Every `NetworkImage` currently in the tree.
List<NetworkImage> networkImages(WidgetTester tester, [Finder? within]) {
  final finder = within == null
      ? find.byType(Image)
      : find.descendant(of: within, matching: find.byType(Image));
  return tester
      .widgetList<Image>(finder)
      .map((image) => image.image)
      .whereType<NetworkImage>()
      .toList();
}

List<String> urlsOf(List<NetworkImage> images) =>
    images.map((image) => image.url).toList();

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('Issue 12: GalleryDesktop', () {
    testWidgets('sends httpHeaders with the slide, poster and PDF images', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          GalleryDesktop(
            items: _items,
            playerFactory: FakeVideoPlayer.new,
            autoScrollEnabled: false,
            httpHeaders: _headers,
          ),
        ),
      );
      await tester.pump();

      final images = networkImages(tester);
      expect(
        urlsOf(images),
        unorderedEquals([_imageUrl, _videoPoster, _pdfPreview]),
      );
      for (final image in images) {
        expect(image.headers, _headers, reason: image.url);
      }
    });

    testWidgets('sends no headers when httpHeaders is not given', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          GalleryDesktop(
            items: _items,
            playerFactory: FakeVideoPlayer.new,
            autoScrollEnabled: false,
          ),
        ),
      );
      await tester.pump();

      final images = networkImages(tester);
      expect(images, hasLength(3));
      for (final image in images) {
        expect(image.headers, isNull, reason: image.url);
      }
    });

    testWidgets('sends httpHeaders with the full-screen image', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          GalleryDesktop(
            items: [GalleryItem.image(_imageUrl, previewUrl: null)],
            playerFactory: FakeVideoPlayer.new,
            autoScrollEnabled: false,
            httpHeaders: _headers,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(Image));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final dialogImages = networkImages(
        tester,
        find.byType(InteractiveViewer),
      );
      expect(urlsOf(dialogImages), [_imageUrl]);
      expect(dialogImages.single.headers, _headers);
    });

    testWidgets('opens the video with httpHeaders', (tester) async {
      tester.view.physicalSize = const Size(2400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final player = FakeVideoPlayer();
      await tester.pumpWidget(
        host(
          GalleryDesktop(
            items: [GalleryItem.video(_videoUrl, previewUrl: _videoPoster)],
            playerFactory: () => player,
            autoScrollEnabled: false,
            httpHeaders: _headers,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_arrow).first);
      await tester.pump();
      await tester.pump();

      expect(player.openedUrls, [_videoUrl]);
      expect(player.openedHeaders, [_headers]);
    });

    testWidgets('opens the video with no headers when none are given', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final player = FakeVideoPlayer();
      await tester.pumpWidget(
        host(
          GalleryDesktop(
            items: [GalleryItem.video(_videoUrl, previewUrl: _videoPoster)],
            playerFactory: () => player,
            autoScrollEnabled: false,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_arrow).first);
      await tester.pump();
      await tester.pump();

      expect(player.openedHeaders, [isEmpty]);
    });
  });

  group('Issue 12: GalleryMobile', () {
    testWidgets('sends httpHeaders with the slides and the thumbnail strip', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          GalleryMobile(
            items: _items,
            playerFactory: FakeVideoPlayer.new,
            autoScrollEnabled: false,
            httpHeaders: _headers,
          ),
        ),
      );
      await tester.pump();

      final thumbnails = networkImages(
        tester,
        find.byType(GalleryThumbnailStrip),
      );
      expect(
        urlsOf(thumbnails),
        unorderedEquals([_imageUrl, _videoPoster, _pdfPreview]),
      );

      final images = networkImages(tester);
      expect(images.length, greaterThan(thumbnails.length));
      for (final image in images) {
        expect(image.headers, _headers, reason: image.url);
      }
    });

    testWidgets('sends no headers when httpHeaders is not given', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          GalleryMobile(
            items: _items,
            playerFactory: FakeVideoPlayer.new,
            autoScrollEnabled: false,
          ),
        ),
      );
      await tester.pump();

      final images = networkImages(tester);
      expect(images, isNotEmpty);
      for (final image in images) {
        expect(image.headers, isNull, reason: image.url);
      }
    });
  });

  group('Issue 12: HighlightMedia', () {
    testWidgets('sends httpHeaders with a remote image', (tester) async {
      await tester.pumpWidget(
        host(const HighlightMedia(url: _imageUrl, httpHeaders: _headers)),
      );
      await tester.pump();

      final images = networkImages(tester);
      expect(urlsOf(images), [_imageUrl]);
      expect(images.single.headers, _headers);
    });

    testWidgets('opens a remote video with httpHeaders', (tester) async {
      final player = FakeVideoPlayer();
      await tester.pumpWidget(
        host(
          HighlightMedia(
            url: _videoUrl,
            playerFactory: () => player,
            httpHeaders: _headers,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(player.openedUrls, [_videoUrl]);
      expect(player.openedHeaders, [_headers]);
    });
  });

  group('Issue 12: PopOverVideoPlayer', () {
    testWidgets('opens the popover video with httpHeaders', (tester) async {
      final player = FakeVideoPlayer();
      await tester.pumpWidget(
        host(
          PopOverVideoPlayer(
            videoUrl: _videoUrl,
            playerFactory: () => player,
            httpHeaders: _headers,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pump();
      await tester.pump();

      expect(player.openedUrls, [_videoUrl]);
      expect(player.openedHeaders, [_headers]);
    });
  });

  group('Issue 12: NativeVideoPlayer', () {
    late VideoPlayerPlatform original;
    late FakeVideoPlayerPlatform platform;

    setUp(() {
      original = VideoPlayerPlatform.instance;
      platform = FakeVideoPlayerPlatform();
      VideoPlayerPlatform.instance = platform;
    });

    tearDown(() => VideoPlayerPlatform.instance = original);

    test('passes httpHeaders to the video controller', () async {
      final player = NativeVideoPlayer();
      await player.initialize();
      await player.open(_videoUrl, autoPlay: false, httpHeaders: _headers);

      expect(platform.dataSources.single.uri, _videoUrl);
      expect(platform.dataSources.single.httpHeaders, _headers);
      player.dispose();
    });

    test('passes no headers when none are given', () async {
      final player = NativeVideoPlayer();
      await player.initialize();
      await player.open(_videoUrl, autoPlay: false);

      expect(platform.dataSources.single.httpHeaders, isEmpty);
      player.dispose();
    });
  });
}
