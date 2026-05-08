import 'package:meta/meta.dart';

/// The kind of media supported by the uploader.
enum MediaKind { image, video, pdf }

/// Server-side conversion lifecycle for an uploaded asset.
enum MediaConversionStatus { pending, processing, completed, failed }

/// Two visual modes the uploader can render in.
enum MediaUploaderMode { single, multi }

/// Per-item lifecycle inside the dialog (UI state, not server state).
enum UploadItemPhase {
  queued,
  uploading,
  converting,
  completed,
  failed,
  cancelled,
}

extension UploadItemPhaseX on UploadItemPhase {
  bool get isTerminal =>
      this == UploadItemPhase.completed ||
      this == UploadItemPhase.failed ||
      this == UploadItemPhase.cancelled;
}

/// Bytes + metadata for a single file to be uploaded.
@immutable
class MediaUploadRequest {
  const MediaUploadRequest({
    required this.bytes,
    required this.filename,
    required this.kind,
    this.mimeType,
    this.usageContext,
  });

  final List<int> bytes;
  final String filename;
  final MediaKind kind;
  final String? mimeType;
  final String? usageContext;
}

/// Result of an upload (and subsequent status polls).
///
/// Constructed by the host app inside its [MediaUploadCallback] /
/// [MediaStatusCallback] — `cl_video_player` never builds this directly
/// from a server payload.
@immutable
class MediaUploadResult {
  const MediaUploadResult({
    required this.id,
    required this.uuid,
    required this.kind,
    required this.status,
    required this.downloadUrl,
    this.error,
  });

  final int id;
  final String uuid;
  final MediaKind kind;
  final MediaConversionStatus status;
  final String downloadUrl;
  final String? error;

  MediaUploadResult copyWith({
    int? id,
    String? uuid,
    MediaKind? kind,
    MediaConversionStatus? status,
    String? downloadUrl,
    String? Function()? error,
  }) {
    return MediaUploadResult(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      error: error != null ? error() : this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MediaUploadResult &&
      other.id == id &&
      other.uuid == uuid &&
      other.kind == kind &&
      other.status == status &&
      other.downloadUrl == downloadUrl &&
      other.error == error;

  @override
  int get hashCode =>
      Object.hash(id, uuid, kind, status, downloadUrl, error);

  @override
  String toString() =>
      'MediaUploadResult(id: $id, uuid: $uuid, kind: $kind, '
      'status: $status, downloadUrl: $downloadUrl, error: $error)';
}

/// Performs the actual upload (host app injects this).
typedef MediaUploadCallback =
    Future<MediaUploadResult> Function(MediaUploadRequest req);

/// Polls server-side conversion status (host app injects this).
typedef MediaStatusCallback =
    Future<MediaUploadResult> Function(int id);

/// Called once at the end with the successfully completed results.
typedef MediaUploadCompleteCallback =
    void Function(List<MediaUploadResult> results);
