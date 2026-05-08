import 'package:meta/meta.dart';

import 'media_upload_types.dart';

/// In-flight state for a single picked file inside the multi dialog.
@immutable
class UploadItemState {
  const UploadItemState({
    required this.localId,
    required this.filename,
    required this.bytes,
    required this.kind,
    required this.phase,
    this.mimeType,
    this.result,
    this.error,
  });

  final String localId;
  final String filename;
  final List<int> bytes;
  final MediaKind kind;
  final String? mimeType;
  final UploadItemPhase phase;
  final MediaUploadResult? result;
  final String? error;

  UploadItemState copyWith({
    UploadItemPhase? phase,
    MediaUploadResult? Function()? result,
    String? Function()? error,
  }) {
    return UploadItemState(
      localId: localId,
      filename: filename,
      bytes: bytes,
      kind: kind,
      mimeType: mimeType,
      phase: phase ?? this.phase,
      result: result != null ? result() : this.result,
      error: error != null ? error() : this.error,
    );
  }
}

/// Predicate for the multi dialog's `Done` button.
///
/// `Done` is enabled iff every item is in a terminal phase **and** at
/// least one item completed successfully.
bool isDoneEnabled(List<UploadItemState> items) {
  if (items.isEmpty) return false;
  final allTerminal = items.every((i) => i.phase.isTerminal);
  if (!allTerminal) return false;
  return items.any((i) => i.phase == UploadItemPhase.completed);
}

/// Successfully completed results, in original pick order.
List<MediaUploadResult> successfulResults(List<UploadItemState> items) {
  return [
    for (final i in items)
      if (i.phase == UploadItemPhase.completed && i.result != null) i.result!,
  ];
}
