import 'package:cl_video_player/cl_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFilePicker {
  FakeFilePicker(this.toReturn);
  final List<PickedMedia> toReturn;
  int callCount = 0;
  bool? lastAllowMultiple;
  Set<MediaKind>? lastAllowedKinds;

  Future<List<PickedMedia>> pick({
    required bool allowMultiple,
    required Set<MediaKind> allowedKinds,
  }) async {
    callCount++;
    lastAllowMultiple = allowMultiple;
    lastAllowedKinds = allowedKinds;
    return toReturn;
  }
}

// 1x1 transparent PNG.
const _tinyPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

PickedMedia imagePick(String name) => PickedMedia(
      bytes: _tinyPng,
      filename: name,
      kind: MediaKind.image,
      mimeType: 'image/png',
    );

MediaUploadResult resultFor(MediaUploadRequest req, {
  MediaConversionStatus status = MediaConversionStatus.completed,
  String? error,
  int id = 1,
}) {
  return MediaUploadResult(
    id: id,
    uuid: 'uuid-${req.filename}',
    kind: req.kind,
    status: status,
    downloadUrl: 'http://x/${req.filename}',
    error: error,
  );
}

Widget host(MediaUploader uploader) => MaterialApp(
      home: Scaffold(body: Center(child: uploader)),
    );

void main() {
  group('MediaUploader (single)', () {
    testWidgets('happy path: callback fires with one result',
        (tester) async {
      final picker = FakeFilePicker([imagePick('a.png')]);
      final completed = <List<MediaUploadResult>>[];

      await tester.pumpWidget(host(MediaUploader(
        mode: MediaUploaderMode.single,
        pickerAdapter: picker.pick,
        uploadCallback: (req) async => resultFor(req),
        statusCallback: (id) async => throw UnimplementedError(),
        onComplete: completed.add,
        triggerBuilder: (_, openPicker) => ElevatedButton(
          onPressed: openPicker,
          child: const Text('Upload'),
        ),
      )));

      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();

      expect(picker.callCount, 1);
      expect(picker.lastAllowMultiple, isFalse);
      expect(completed, hasLength(1));
      expect(completed.single, hasLength(1));
      expect(completed.single.single.kind, MediaKind.image);
    });

    testWidgets('failure path: shows snackbar, no callback', (tester) async {
      final picker = FakeFilePicker([imagePick('a.png')]);
      final completed = <List<MediaUploadResult>>[];

      await tester.pumpWidget(host(MediaUploader(
        mode: MediaUploaderMode.single,
        pickerAdapter: picker.pick,
        uploadCallback: (req) async => resultFor(
          req,
          status: MediaConversionStatus.failed,
          error: 'too big',
        ),
        statusCallback: (id) async => throw UnimplementedError(),
        onComplete: completed.add,
        triggerBuilder: (_, openPicker) => ElevatedButton(
          onPressed: openPicker,
          child: const Text('Upload'),
        ),
      )));

      await tester.tap(find.text('Upload'));
      // Allow upload to fail and the dialog to close.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      // Snackbar is now showing (but its auto-dismiss timer will fire if
      // we let pumpAndSettle run, so we pump just enough for it to appear).
      await tester.pump();

      expect(completed, isEmpty);
      expect(find.text('too big'), findsOneWidget);
      // Drain remaining timers so the test cleans up.
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('user cancel via empty picker: no dialog, no callback',
        (tester) async {
      final picker = FakeFilePicker(const []);
      final completed = <List<MediaUploadResult>>[];

      await tester.pumpWidget(host(MediaUploader(
        mode: MediaUploaderMode.single,
        pickerAdapter: picker.pick,
        uploadCallback: (req) async => resultFor(req),
        statusCallback: (id) async => throw UnimplementedError(),
        onComplete: completed.add,
        triggerBuilder: (_, openPicker) => ElevatedButton(
          onPressed: openPicker,
          child: const Text('Upload'),
        ),
      )));

      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();

      expect(picker.callCount, 1);
      expect(completed, isEmpty);
    });
  });

  group('MediaUploader (multi)', () {
    testWidgets(
        'Done enabled only after all terminal; payload excludes failures',
        (tester) async {
      final picker = FakeFilePicker([
        imagePick('a.png'),
        imagePick('b.png'),
        imagePick('c.png'),
      ]);
      final completed = <List<MediaUploadResult>>[];

      await tester.pumpWidget(host(MediaUploader(
        mode: MediaUploaderMode.multi,
        pickerAdapter: picker.pick,
        uploadCallback: (req) async {
          if (req.filename == 'b.png') {
            return resultFor(
              req,
              status: MediaConversionStatus.failed,
              error: 'rejected',
              id: 2,
            );
          }
          return resultFor(req);
        },
        statusCallback: (id) async => throw UnimplementedError(),
        onComplete: completed.add,
        triggerBuilder: (_, openPicker) => ElevatedButton(
          onPressed: openPicker,
          child: const Text('Upload'),
        ),
      )));

      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();

      expect(picker.lastAllowMultiple, isTrue);
      expect(find.byType(FilledButton), findsOneWidget);
      // Done is now enabled (all terminal, ≥1 success).
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(completed, hasLength(1));
      // Only successful items are passed.
      expect(completed.single.map((r) => r.uuid).toList(), [
        'uuid-a.png',
        'uuid-c.png',
      ]);
    });
  });
}
