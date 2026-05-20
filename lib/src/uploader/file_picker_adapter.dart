import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'media_upload_types.dart';

/// A picked-but-not-yet-uploaded file.
@immutable
class PickedMedia {
  const PickedMedia({
    required this.bytes,
    required this.filename,
    required this.kind,
    this.mimeType,
  });

  final List<int> bytes;
  final String filename;
  final MediaKind kind;
  final String? mimeType;
}

/// Abstraction over the `file_picker` package so widget tests can substitute
/// a fake.
typedef FilePickerAdapter = Future<List<PickedMedia>> Function({
  required bool allowMultiple,
  required Set<MediaKind> allowedKinds,
});

/// Production adapter — wraps `FilePicker.platform`.
Future<List<PickedMedia>> defaultFilePicker({
  required bool allowMultiple,
  required Set<MediaKind> allowedKinds,
}) async {
  final extensions = _extensionsFor(allowedKinds);
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: allowMultiple,
    type: FileType.custom,
    allowedExtensions: extensions,
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    return const [];
  }
  final picked = <PickedMedia>[];
  for (final file in result.files) {
    final bytes = file.bytes;
    if (bytes == null) {
      continue;
    }
    final kind = _kindFor(file.extension, allowedKinds);
    if (kind == null) {
      continue;
    }
    picked.add(
      PickedMedia(
        bytes: bytes,
        filename: file.name,
        kind: kind,
        mimeType: _mimeFor(file.extension),
      ),
    );
  }
  return picked;
}

List<String> _extensionsFor(Set<MediaKind> kinds) {
  final ext = <String>[];
  if (kinds.contains(MediaKind.image)) {
    ext.addAll(['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic']);
  }
  if (kinds.contains(MediaKind.video)) {
    ext.addAll(['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp']);
  }
  if (kinds.contains(MediaKind.pdf)) {
    ext.add('pdf');
  }
  return ext;
}

MediaKind? _kindFor(String? ext, Set<MediaKind> allowed) {
  if (ext == null) return null;
  final e = ext.toLowerCase();
  const imageExts = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic'};
  const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'};
  if (imageExts.contains(e) && allowed.contains(MediaKind.image)) {
    return MediaKind.image;
  }
  if (videoExts.contains(e) && allowed.contains(MediaKind.video)) {
    return MediaKind.video;
  }
  if (e == 'pdf' && allowed.contains(MediaKind.pdf)) {
    return MediaKind.pdf;
  }
  return null;
}

String? _mimeFor(String? ext) {
  if (ext == null) return null;
  switch (ext.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'bmp':
      return 'image/bmp';
    case 'heic':
      return 'image/heic';
    case 'mp4':
    case 'm4v':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'avi':
      return 'video/x-msvideo';
    case 'mkv':
      return 'video/x-matroska';
    case 'webm':
      return 'video/webm';
    case '3gp':
      return 'video/3gpp';
    case 'pdf':
      return 'application/pdf';
  }
  return null;
}
