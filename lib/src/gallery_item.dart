import 'package:flutter/foundation.dart';

enum GalleryItemType { image, video }

@immutable
class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.url,
    required this.type,
  });

  final String id;
  final String url;
  final GalleryItemType type;

  factory GalleryItem.image(String url, {String? id}) {
    return GalleryItem(
      id: id ?? url,
      url: url,
      type: GalleryItemType.image,
    );
  }

  factory GalleryItem.video(String url, {String? id}) {
    return GalleryItem(
      id: id ?? url,
      url: url,
      type: GalleryItemType.video,
    );
  }

  bool get isImage => type == GalleryItemType.image;
  bool get isVideo => type == GalleryItemType.video;

  GalleryItem copyWith({
    String? id,
    String? url,
    GalleryItemType? type,
  }) {
    return GalleryItem(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryItem &&
        other.id == id &&
        other.url == url &&
        other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ url.hashCode ^ type.hashCode;

  @override
  String toString() => 'GalleryItem(id: $id, url: $url, type: $type)';
}
