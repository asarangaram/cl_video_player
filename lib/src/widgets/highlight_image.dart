import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'highlight_image_io.dart'
    if (dart.library.html) 'highlight_image_web.dart' as platform;

/// Displays an image from network, asset, or file path.
///
/// Supports:
/// - Network URLs (http:// or https://)
/// - Asset paths (starting with 'asset')
/// - File paths (platform-specific, not supported on web)
class HighlightImage extends StatelessWidget {
  const HighlightImage({
    required this.uri, required this.fit, super.key,
    this.onTap,
  });

  final String uri;
  final BoxFit fit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageWidget = buildImageWidget(context);

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget buildImageWidget(BuildContext context) {
    final isNetwork = uri.startsWith('http://') || uri.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        uri,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: buildLoadingIndicator,
        errorBuilder: buildErrorWidget,
      );
    }

    if (uri.startsWith('asset')) {
      return Image.asset(
        uri,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: buildErrorWidget,
      );
    }

    // Use platform-specific implementation for file images
    return platform.buildFileImage(uri, fit, buildErrorWidget);
  }

  Widget buildLoadingIndicator(
    BuildContext context,
    Widget child,
    ImageChunkEvent? progress,
  ) {
    if (progress == null) return child;

    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.muted,
      child: Center(
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  Widget buildErrorWidget(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.muted,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );
  }
}
