import 'package:cl_video_player/cl_video_player.dart';
import 'package:cl_video_player/src/uploader/upload_item_state.dart';
import 'package:flutter_test/flutter_test.dart';

UploadItemState item({
  required String id,
  required UploadItemPhase phase,
  MediaUploadResult? result,
}) {
  return UploadItemState(
    localId: id,
    filename: '$id.bin',
    bytes: const [0],
    kind: MediaKind.image,
    phase: phase,
    result: result,
  );
}

const _ok = MediaUploadResult(
  id: 1,
  uuid: 'u',
  kind: MediaKind.image,
  status: MediaConversionStatus.completed,
  downloadUrl: 'http://x/u',
);

void main() {
  group('isDoneEnabled', () {
    test('false when items list is empty', () {
      expect(isDoneEnabled(const []), isFalse);
    });

    test('false while any item is non-terminal', () {
      expect(
        isDoneEnabled([
          item(id: 'a', phase: UploadItemPhase.completed, result: _ok),
          item(id: 'b', phase: UploadItemPhase.uploading),
        ]),
        isFalse,
      );
    });

    test('false when all terminal but none completed', () {
      expect(
        isDoneEnabled([
          item(id: 'a', phase: UploadItemPhase.failed),
          item(id: 'b', phase: UploadItemPhase.cancelled),
        ]),
        isFalse,
      );
    });

    test('true when all terminal and at least one completed', () {
      expect(
        isDoneEnabled([
          item(id: 'a', phase: UploadItemPhase.completed, result: _ok),
          item(id: 'b', phase: UploadItemPhase.failed),
        ]),
        isTrue,
      );
    });
  });

  group('successfulResults', () {
    test('returns only completed items, in order', () {
      const r2 = MediaUploadResult(
        id: 2,
        uuid: 'v',
        kind: MediaKind.video,
        status: MediaConversionStatus.completed,
        downloadUrl: 'http://x/v',
      );
      final out = successfulResults([
        item(id: 'a', phase: UploadItemPhase.completed, result: _ok),
        item(id: 'b', phase: UploadItemPhase.failed),
        item(id: 'c', phase: UploadItemPhase.completed, result: r2),
      ]);
      expect(out, [_ok, r2]);
    });

    test('drops completed items with null result', () {
      final out = successfulResults([
        item(id: 'a', phase: UploadItemPhase.completed),
      ]);
      expect(out, isEmpty);
    });
  });
}
