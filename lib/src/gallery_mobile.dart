import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'full_screen_image.dart';
import 'gallery_item.dart';
import 'gallery_pdf_card.dart';
import 'gallery_thumbnail_strip.dart';
import 'gallery_video_player.dart';

class GalleryMobile extends StatefulWidget {
  const GalleryMobile({
    required this.items,
    required this.playerFactory,
    super.key,
    this.onPdfDownload,
    this.height = 250.0,
    this.imageSpacing = 16.0,
    this.viewportFraction = 0.70,
    this.autoScrollEnabled = true,
    this.autoScrollInterval = const Duration(seconds: 3),
    this.autoScrollDuration = const Duration(milliseconds: 800),
  });

  final List<GalleryItem> items;
  final VideoPlayerFactory playerFactory;

  /// Called when a PDF item's download button is tapped. Receives the PDF URL.
  final ValueChanged<String>? onPdfDownload;

  final double height;
  final double imageSpacing;
  final double viewportFraction;
  final bool autoScrollEnabled;
  final Duration autoScrollInterval;
  final Duration autoScrollDuration;

  @override
  State<GalleryMobile> createState() => GalleryMobileState();
}

class GalleryMobileState extends State<GalleryMobile> {
  late PageController pageController;
  int currentPage = 0;

  bool autoScrollEnabled = true;
  Timer? autoScrollTimer;
  String? activeVideoId;

  @override
  void initState() {
    super.initState();
    autoScrollEnabled = widget.autoScrollEnabled;
    pageController = PageController(viewportFraction: widget.viewportFraction);
    pageController.addListener(handlePageScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (autoScrollEnabled) {
        startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    stopAutoScroll();
    pageController
      ..removeListener(handlePageScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('No items available')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: pageController,
            itemCount: widget.items.length,
            onPageChanged: handlePageChanged,
            itemBuilder: (context, index) {
              return buildItemCard(widget.items[index], index);
            },
          ),
        ),
        const SizedBox(height: 8),
        GalleryThumbnailStrip(
          items: widget.items,
          selectedIndex: currentPage,
          onThumbnailTap: handleThumbnailTap,
        ),
      ],
    );
  }

  Widget buildItemCard(GalleryItem item, int index) {
    final isCenter = index == currentPage;

    final Widget content;
    if (item.isPdf) {
      content = GalleryPdfCard(
        pdfUrl: item.url,
        onDownload: () => widget.onPdfDownload?.call(item.url),
      );
    } else if (item.isVideo) {
      content = GalleryVideoPlayer(
        videoUrl: item.url,
        videoId: item.id,
        isActiveVideo: activeVideoId == item.id,
        onPlayStateChanged: handleVideoPlayStateChanged,
        playerFactory: widget.playerFactory,
        autoLoadVideo: isCenter,
      );
    } else {
      content = buildImage(item.url);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.imageSpacing / 2),
      child: content,
    );
  }

  Widget buildImage(String imageUrl) {
    final isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    final Widget image;
    if (isNetworkImage) {
      image = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: buildLoadingIndicator,
        errorBuilder: buildErrorWidget,
      );
    } else {
      image = Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: buildErrorWidget,
      );
    }

    return GestureDetector(
      onTap: () => showFullScreenImage(context, imageUrl),
      child: image,
    );
  }

  void handleVideoPlayStateChanged(String videoId, {required bool isPlaying}) {
    if (isPlaying) {
      setState(() => activeVideoId = videoId);
      if (autoScrollEnabled) disableAutoScrollOnInteraction();
    } else if (activeVideoId == videoId) {
      setState(() => activeVideoId = null);
    }
  }

  Widget buildLoadingIndicator(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) return child;
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.muted,
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
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

  // Page navigation

  void handlePageScroll() {
    final page = pageController.page?.round() ?? 0;
    if (page != currentPage) {
      setState(() => currentPage = page);
    }
  }

  void handlePageChanged(int page) {
    if (autoScrollEnabled) disableAutoScrollOnInteraction();
    setState(() => currentPage = page);
  }

  void handleThumbnailTap(int index) {
    if (autoScrollEnabled) disableAutoScrollOnInteraction();
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Auto-scroll

  void disableAutoScrollOnInteraction() {
    setState(() => autoScrollEnabled = false);
    stopAutoScroll();
  }

  void startAutoScroll() {
    stopAutoScroll();
    autoScrollTimer = Timer.periodic(widget.autoScrollInterval, (_) {
      performAutoScroll();
    });
  }

  void stopAutoScroll() {
    autoScrollTimer?.cancel();
    autoScrollTimer = null;
  }

  void performAutoScroll() {
    if (activeVideoId != null) return;
    if (!pageController.hasClients) return;

    final nextPage = currentPage + 1;
    if (nextPage < widget.items.length) {
      pageController.animateToPage(
        nextPage,
        duration: widget.autoScrollDuration,
        curve: Curves.easeInOut,
      );
    } else {
      pageController.animateToPage(
        0,
        duration: widget.autoScrollDuration,
        curve: Curves.easeInOut,
      );
    }
  }
}
