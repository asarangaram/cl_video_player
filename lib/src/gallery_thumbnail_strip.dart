import 'package:flutter/material.dart';

import 'gallery_item.dart';
import 'video_url_utils.dart';

class GalleryThumbnailStrip extends StatelessWidget {
  const GalleryThumbnailStrip({
    required this.items,
    required this.selectedIndex,
    required this.onThumbnailTap,
    super.key,
    this.thumbnailHeight = 50.0,
    this.thumbnailWidth = 70.0,
    this.spacing = 8.0,
  });

  final List<GalleryItem> items;
  final int selectedIndex;
  final ValueChanged<int> onThumbnailTap;
  final double thumbnailHeight;
  final double thumbnailWidth;
  final double spacing;

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
    final String imageUrl;
    if (item.isVideo) {
      imageUrl = VideoUrlUtils.getPosterUrl(item.url);
    } else if (item.isPdf) {
      imageUrl = VideoUrlUtils.getPdfPreviewUrl(item.url);
    } else {
      imageUrl = item.url;
    }

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
                Image.network(
                  imageUrl,
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
