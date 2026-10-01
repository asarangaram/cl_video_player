import 'package:flutter/material.dart';

import 'gallery_item.dart';
import 'utils/http_headers.dart';

class GalleryThumbnailStrip extends StatelessWidget {
  const GalleryThumbnailStrip({
    required this.items,
    required this.selectedIndex,
    required this.onThumbnailTap,
    super.key,
    this.thumbnailHeight = 50.0,
    this.thumbnailWidth = 70.0,
    this.spacing = 8.0,
    this.httpHeaders = const {},
  });

  final List<GalleryItem> items;
  final int selectedIndex;
  final ValueChanged<int> onThumbnailTap;
  final double thumbnailHeight;
  final double thumbnailWidth;
  final double spacing;

  /// Request headers sent with the thumbnail images. Empty, none are sent.
  final Map<String, String> httpHeaders;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thumbnailHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: EdgeInsets.symmetric(horizontal: spacing),
        itemBuilder: (context, index) {
          return buildThumbnail(index);
        },
      ),
    );
  }

  Widget buildThumbnail(int index) {
    final item = items[index];
    final isSelected = index == selectedIndex;
    // An image is its own preview. A video or PDF shows only the preview the
    // caller gave; with none it gets the placeholder, never a guessed URL.
    final imageUrl = item.isImage
        ? item.previewUrl ?? item.url
        : item.previewUrl;

    return GestureDetector(
      onTap: () => onThumbnailTap(index),
      child: Container(
        width: thumbnailWidth,
        height: thumbnailHeight,
        margin: EdgeInsets.only(right: spacing),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl == null)
                  ColoredBox(color: Colors.grey[800]!)
                else
                  Image.network(
                    imageUrl,
                    headers: imageRequestHeaders(httpHeaders),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                if (item.isVideo || item.isPdf)
                  Center(
                    child: Container(
                      width: thumbnailHeight * 0.45,
                      height: thumbnailHeight * 0.45,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.isPdf ? Icons.picture_as_pdf : Icons.play_arrow,
                        color: Colors.white,
                        size: thumbnailHeight * 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
