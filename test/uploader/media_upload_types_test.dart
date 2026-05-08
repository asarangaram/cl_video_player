import 'package:cl_video_player/cl_video_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UploadItemPhase.isTerminal', () {
    test('completed, failed, cancelled are terminal', () {
      expect(UploadItemPhase.completed.isTerminal, isTrue);
      expect(UploadItemPhase.failed.isTerminal, isTrue);
      expect(UploadItemPhase.cancelled.isTerminal, isTrue);
    });

    test('queued, uploading, converting are not terminal', () {
      expect(UploadItemPhase.queued.isTerminal, isFalse);
      expect(UploadItemPhase.uploading.isTerminal, isFalse);
      expect(UploadItemPhase.converting.isTerminal, isFalse);
    });
  });

  group('MediaUploadResult', () {
    const a = MediaUploadResult(
      id: 1,
      uuid: 'u',
      kind: MediaKind.image,
      status: MediaConversionStatus.completed,
      downloadUrl: 'http://x/u',
    );

    test('equality is value-based', () {
      const b = MediaUploadResult(
        id: 1,
        uuid: 'u',
        kind: MediaKind.image,
        status: MediaConversionStatus.completed,
        downloadUrl: 'http://x/u',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith updates only the requested fields', () {
      final c = a.copyWith(status: MediaConversionStatus.failed);
      expect(c.status, MediaConversionStatus.failed);
      expect(c.id, a.id);
      expect(c.uuid, a.uuid);
      expect(c.error, isNull);
    });

    test('copyWith ValueGetter clears nullable error', () {
      final withErr = a.copyWith(error: () => 'boom');
      expect(withErr.error, 'boom');
      final cleared = withErr.copyWith(error: () => null);
      expect(cleared.error, isNull);
    });

    test('copyWith without error param preserves error', () {
      final withErr = a.copyWith(error: () => 'boom');
      final next = withErr.copyWith(status: MediaConversionStatus.failed);
      expect(next.error, 'boom');
    });
  });
}
