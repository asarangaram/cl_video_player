import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'gallery_item.dart';
import 'gallery_navigation_button.dart';
import 'full_screen_image.dart';
import 'gallery_pdf_card.dart';
import 'gallery_video_player.dart';

class GalleryDesktop extends StatefulWidget {
  const GalleryDesktop({
    super.key,
    required this.items,
    required this.playerFactory,
    this.onPdfDownload,
    this.height = 300.0,
    this.imageSpacing = 16.0,
    this.navigationButtonSize = 56.0,
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
  final double navigationButtonSize;
  final bool autoScrollEnabled;
  final Duration autoScrollInterval;
  final Duration autoScrollDuration;

  @override
  State<GalleryDesktop> createState() => GalleryDesktopState();
}

class GalleryDesktopState extends State<GalleryDesktop> {
  late ScrollController scrollController;
  double scrollOffset = 0;
  double maxScrollExtent = 0;
  double currentImageWidth = 280;

  bool autoScrollEnabled = true;
  Timer? autoScrollTimer;
  String? activeVideoId;

  bool get canGoBack => scrollOffset > 0;
  bool get canGoForward => scrollOffset < maxScrollExtent;

  @override
  void initState() {
    super.initState();
    autoScrollEnabled = widget.autoScrollEnabled;
    scrollController = ScrollController();
    scrollController.addListener(handleScrollUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeScrollExtent();
      if (autoScrollEnabled) {
        startAutoScroll();
      }
    });
  }

  void initializeScrollExtent() {
    if (scrollController.hasClients) {
      setState(() {
        scrollOffset = scrollController.offset;
        maxScrollExtent = scrollController.position.maxScrollExtent;
      });
    }
  }

  @override
  void dispose() {
    stopAutoScroll();
    scrollController.removeListener(handleScrollUpdate);
    scrollController.dispose();
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

    return LayoutBuilder(
      builder: (context, constraints) {
        currentImageWidth = calculateImageWidth(constraints.maxWidth);

        return SizedBox(
          height: widget.height,
          child: Row(
            children: [
              buildNavButton(NavigationDirection.left),
              Expanded(
                child: Stack(
                  children: [
                    buildItemList(currentImageWidth),
                    buildAutoScrollToggle(),
                  ],
                ),
              ),
              buildNavButton(NavigationDirection.right),
            ],
          ),
        );
      },
    );
  }

  double calculateImageWidth(double availableWidth) {
    final fractionWidth = availableWidth * 0.28;
    return fractionWidth > 280 ? fractionWidth : 280.0;
  }

  Widget buildNavButton(NavigationDirection direction) {
    final isLeft = direction == NavigationDirection.left;
    final canNavigate = isLeft ? canGoBack : canGoForward;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: canNavigate ? 1.0 : 0.3,
          child: GalleryNavigationButton(
            direction: direction,
            size: widget.navigationButtonSize,
            onPressed: canNavigate
                ? () => handleNavigationPress(
                    isLeft ? -currentImageWidth : currentImageWidth)
                : () {},
          ),
        ),
      ),
    );
  }

  Widget buildItemList(double itemWidth) {
    return NotificationListener<ScrollNotification>(
      onNotification: handleScrollNotification,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          return buildItemCard(widget.items[index], itemWidth, index);
        },
      ),
    );
  }

  Widget buildItemCard(GalleryItem item, double itemWidth, int index) {
    final isLast = index == widget.items.length - 1;

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
      );
    } else {
      content = buildImage(item.url);
    }

    return Padding(
      padding: EdgeInsets.only(right: isLast ? 0 : widget.imageSpacing),
      child: SizedBox(width: itemWidth, child: content),
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

  void handleVideoPlayStateChanged(String videoId, bool isPlaying) {
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
    return Container(
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
    return Container(
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

  // Auto-scroll

  Widget buildAutoScrollToggle() {
    return Positioned(
      right: 8,
      top: 8,
      child: AutoScrollToggleButton(
        isEnabled: autoScrollEnabled,
        onToggle: toggleAutoScroll,
      ),
    );
  }

  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null && autoScrollEnabled) {
        disableAutoScrollOnInteraction();
      }
    }
    return false;
  }

  void handleScrollUpdate() {
    setState(() {
      scrollOffset = scrollController.offset;
      maxScrollExtent = scrollController.position.maxScrollExtent;
    });
  }

  void handleNavigationPress(double amount) {
    if (autoScrollEnabled) disableAutoScrollOnInteraction();
    scrollByAmount(amount);
  }

  void scrollByAmount(double amount) {
    final targetOffset = (scrollController.offset + amount).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );
    scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void disableAutoScrollOnInteraction() {
    setState(() => autoScrollEnabled = false);
    stopAutoScroll();
  }

  void toggleAutoScroll() {
    setState(() => autoScrollEnabled = !autoScrollEnabled);
    if (autoScrollEnabled) {
      startAutoScroll();
    } else {
      stopAutoScroll();
    }
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
    if (!scrollController.hasClients) return;
    if (activeVideoId != null) return;

    final scrollAmount = currentImageWidth + widget.imageSpacing;
    if (canGoForward) {
      scrollController.animateTo(
        scrollController.offset + scrollAmount,
        duration: widget.autoScrollDuration,
        curve: Curves.easeInOut,
      );
    } else {
      scrollController.animateTo(
        0,
        duration: widget.autoScrollDuration,
        curve: Curves.easeInOut,
      );
    }
  }
}

class AutoScrollToggleButton extends StatefulWidget {
  const AutoScrollToggleButton({
    super.key,
    required this.isEnabled,
    required this.onToggle,
  });

  final bool isEnabled;
  final VoidCallback onToggle;

  @override
  State<AutoScrollToggleButton> createState() => AutoScrollToggleButtonState();
}

class AutoScrollToggleButtonState extends State<AutoScrollToggleButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isHovered ? 1.0 : 0.7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isEnabled ? Icons.pause : Icons.play_arrow,
                size: 18,
                color: Colors.black87,
              ),
              const SizedBox(width: 4),
              Text(
                widget.isEnabled ? 'Auto' : 'Play',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
