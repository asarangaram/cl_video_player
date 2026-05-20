import 'package:flutter/material.dart';

enum NavigationDirection { left, right }

class GalleryNavigationButton extends StatefulWidget {
  const GalleryNavigationButton({
    required this.direction, required this.onPressed, super.key,
    this.size = 56.0,
    this.iconSize = 28.0,
    this.normalOpacity = 0.6,
    this.focusedOpacity = 1.0,
  });

  final NavigationDirection direction;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final double normalOpacity;
  final double focusedOpacity;

  @override
  State<GalleryNavigationButton> createState() =>
      GalleryNavigationButtonState();
}

class GalleryNavigationButtonState extends State<GalleryNavigationButton> {
  bool isHovered = false;
  bool isFocused = false;

  bool get isHighlighted => isHovered || isFocused;

  BorderRadius get borderRadius {
    final radius = Radius.circular(widget.size);
    if (widget.direction == NavigationDirection.left) {
      return BorderRadius.only(topRight: radius, bottomRight: radius);
    }
    return BorderRadius.only(topLeft: radius, bottomLeft: radius);
  }

  IconData get icon {
    return widget.direction == NavigationDirection.left
        ? Icons.chevron_left
        : Icons.chevron_right;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => handleFocusChange(focused: focused),
      child: MouseRegion(
        onEnter: (_) => handleHoverChange(hovered: true),
        onExit: (_) => handleHoverChange(hovered: false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: isHighlighted
                    ? widget.focusedOpacity
                    : widget.normalOpacity,
              ),
              borderRadius: borderRadius,
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                size: widget.iconSize,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void handleHoverChange({required bool hovered}) {
    setState(() => isHovered = hovered);
  }

  void handleFocusChange({required bool focused}) {
    setState(() => isFocused = focused);
  }
}
