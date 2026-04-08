import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/media_control.dart';

/// Style options for [AudioControllerAudioMute].
enum AudioMuteButtonStyle { icon, shadButton }

/// A button widget that toggles global audio mute state.
///
/// Reads and writes [mediaControlProvider] to control mute across
/// all [HighlightMedia] video players.
///
/// Can render as either a styled icon button or a [ShadButton].
class AudioControllerAudioMute extends ConsumerWidget {
  const AudioControllerAudioMute({
    super.key,
    this.style = AudioMuteButtonStyle.icon,
    this.size = 20.0,
  });

  /// Whether to render as a styled icon button or a ShadButton.
  final AudioMuteButtonStyle style;

  /// Icon size.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(
      mediaControlProvider.select((s) => s.isMuted),
    );

    final icon = Icon(
      isMuted ? Icons.volume_off : Icons.volume_up,
      color: Colors.white,
      size: size,
    );

    switch (style) {
      case AudioMuteButtonStyle.icon:
        return OverlayIconButton(
          icon: icon,
          onPressed: () => ref.read(mediaControlProvider.notifier).toggleMute(),
        );
      case AudioMuteButtonStyle.shadButton:
        return ShadButton.ghost(
          onPressed: () => ref.read(mediaControlProvider.notifier).toggleMute(),
          child: icon,
        );
    }
  }
}

/// Styled overlay icon button with semi-transparent background.
///
/// Used for overlay controls on media players. Has hover animation
/// that changes background opacity.
class OverlayIconButton extends StatefulWidget {
  const OverlayIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final Widget icon;
  final VoidCallback onPressed;

  @override
  State<OverlayIconButton> createState() => OverlayIconButtonState();
}

class OverlayIconButtonState extends State<OverlayIconButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: isHovered ? 0.8 : 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.icon,
        ),
      ),
    );
  }
}
