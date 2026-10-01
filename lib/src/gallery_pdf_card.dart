import 'package:flutter/material.dart';

import 'utils/http_headers.dart';

/// Gallery card for PDF items.
///
/// Displays the caller's preview image of the first page with a download button
/// overlay and a PDF badge. The caller provides the [onDownload] callback
/// to handle platform-specific download/open behavior.
class GalleryPdfCard extends StatelessWidget {
  const GalleryPdfCard({
    required this.pdfUrl,
    required this.onDownload,
    required this.previewUrl,
    super.key,
    this.httpHeaders = const {},
  });

  /// The original PDF URL.
  final String pdfUrl;

  /// Where the page image lives, or null for none — which shows the
  /// placeholder. Never derived from [pdfUrl].
  final String? previewUrl;

  /// Called when the download button is tapped.
  final VoidCallback onDownload;

  /// Request headers sent with the preview image. Empty, none are sent.
  final Map<String, String> httpHeaders;

  @override
  Widget build(BuildContext context) {
    final preview = previewUrl;

    return GestureDetector(
      onTap: onDownload,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (preview == null)
            buildPlaceholder()
          else
            buildPreviewImage(preview),
          buildDownloadButton(),
          buildPdfBadge(),
        ],
      ),
    );
  }

  Widget buildPreviewImage(String previewUrl) {
    return Image.network(
      previewUrl,
      headers: imageRequestHeaders(httpHeaders),
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
      errorBuilder: (context, error, stack) => buildPlaceholder(),
    );
  }

  Widget buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 48),
      ),
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
