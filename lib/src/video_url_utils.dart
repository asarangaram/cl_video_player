/// Utility class for video URL transformations.
///
/// URL pattern (from media_convert.sh):
/// - Original: club_video.mp4
/// - Animated WebP: club_video.webp
/// - Poster: club_video_poster.webp
class VideoUrlUtils {
  VideoUrlUtils._();

  /// Supported video extensions
  static const _videoExtensions = ['.mp4', '.m4v', '.mov', '.webm', '.avi'];

  /// Strips query parameters from URL for extension checking.
  ///
  /// Example: `video.mp4?v=123` -> `video.mp4`
  static String _stripQuery(String url) {
    final queryIndex = url.indexOf('?');
    return queryIndex == -1 ? url : url.substring(0, queryIndex);
  }

  /// Get the animated WebP URL from a video URL.
  ///
  /// Example: `club_video.mp4` -> `club_video.webp`
  /// Example: `club_video.mp4?v=123` -> `club_video.webp`
  static String getWebpUrl(String videoUrl) {
    final urlWithoutQuery = _stripQuery(videoUrl);
    final lowerUrl = urlWithoutQuery.toLowerCase();

    for (final ext in _videoExtensions) {
      if (lowerUrl.endsWith(ext)) {
        final base = urlWithoutQuery.substring(
          0,
          urlWithoutQuery.length - ext.length,
        );
        return '$base.webp';
      }
    }

    // If no known extension, just append .webp
    return '$urlWithoutQuery.webp';
  }

  /// Get the poster image URL from a video URL.
  ///
  /// Example: `club_video.mp4` -> `club_video_poster.webp`
  /// Example: `club_video.mp4?v=123` -> `club_video_poster.webp`
  static String getPosterUrl(String videoUrl) {
    final urlWithoutQuery = _stripQuery(videoUrl);
    final lowerUrl = urlWithoutQuery.toLowerCase();

    for (final ext in _videoExtensions) {
      if (lowerUrl.endsWith(ext)) {
        final base = urlWithoutQuery.substring(
          0,
          urlWithoutQuery.length - ext.length,
        );
        return '${base}_poster.webp';
      }
    }

    // If no known extension, just append _poster.webp
    return '${urlWithoutQuery}_poster.webp';
  }

  /// Check if URL points to a video file.
  static bool isVideoUrl(String url) {
    final lowerUrl = _stripQuery(url).toLowerCase();
    return _videoExtensions.any(lowerUrl.endsWith) ||
        lowerUrl.endsWith('.m3u8');
  }

  /// Check if URL points to an animated WebP (not a video, but used as
  /// preview).
  static bool isAnimatedWebpUrl(String url) {
    final lowerUrl = _stripQuery(url).toLowerCase();
    return lowerUrl.endsWith('.webp') && !lowerUrl.endsWith('_poster.webp');
  }

  /// Check if URL points to a PDF file.
  static bool isPdfUrl(String url) {
    final lowerUrl = _stripQuery(url).toLowerCase();
    return lowerUrl.endsWith('.pdf');
  }

  /// Get the preview image URL from a PDF URL.
  ///
  /// Example: `document.pdf` -> `document_poster.png`
  /// Example: `document.pdf?v=123` -> `document_poster.png`
  static String getPdfPreviewUrl(String pdfUrl) {
    final urlWithoutQuery = _stripQuery(pdfUrl);
    final lowerUrl = urlWithoutQuery.toLowerCase();

    if (lowerUrl.endsWith('.pdf')) {
      final base = urlWithoutQuery.substring(0, urlWithoutQuery.length - 4);
      return '${base}_poster.png';
    }

    return '${urlWithoutQuery}_poster.png';
  }
}
