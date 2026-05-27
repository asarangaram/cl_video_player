import 'package:flutter/material.dart';

import 'video_url_utils.dart';

/// Gallery card for PDF items.
///
/// Displays a server-provided `.webp` preview image with a download button
/// overlay and a PDF badge. The caller provides the [onDownload] callback
/// to handle platform-specific download/open behavior.
class GalleryPdfCard extends StatelessWidget {
  const GalleryPdfCard({
    required this.pdfUrl,
    required this.onDownload,
    super.key,
  });

  /// The original PDF URL (used to derive the preview image URL).
  final String pdfUrl;

  /// Called when the download button is tapped.
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final previewUrl = VideoUrlUtils.getPdfPreviewUrl(pdfUrl);

    return GestureDetector(
      onTap: onDownload,
      child: Stack(
        fit: StackFit.expand,
        children: [
          buildPreviewImage(previewUrl),
          buildDownloadButton(),
          buildPdfBadge(),
        ],
      ),
    );
  }

  Widget buildPreviewImage(String previewUrl) {
    return Image.network(
      previewUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 48),
          ),
        );
      },
    );
  }

  Widget buildDownloadButton() {
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.download,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget buildPdfBadge() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'PDF',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
