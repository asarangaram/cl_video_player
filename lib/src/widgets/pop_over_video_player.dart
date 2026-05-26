import 'package:flutter/material.dart';

import '../gallery_video_player.dart' show VideoPlayerFactory;
import 'audio_controller_audio_mute.dart' show OverlayIconButton;
import 'pop_over_video_player_overlay.dart';

/// A button that opens a popover video player in the bottom-right corner.
///
/// Accepts an optional [videoUrl]. When null, the button is disabled.
/// On tap, inserts an [OverlayEntry] with [PopOverVideoPlayerOverlay]
/// that plays the video with auto-play.
class PopOverVideoPlayer extends StatelessWidget {
  const PopOverVideoPlayer({
    super.key,
    this.videoUrl,
    this.playerFactory,
    this.size = 20.0,
    this.isMobile,
  });

  /// The video URL to play in the popup. If null, button is disabled.
  final String? videoUrl;

  /// Factory to create the video player for the popup.
  final VideoPlayerFactory? playerFactory;

  /// Icon size.
  final double size;

  /// Resolves whether the popover should use its mobile layout. Forwarded
  /// to [PopOverVideoPlayerOverlay]; when null it falls back to the
  /// overlay's default breakpoint.
  final bool Function(BuildContext context)? isMobile;

  @override
  Widget build(BuildContext context) {
    final isEnabled = videoUrl != null;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: OverlayIconButton(
        icon: Icon(
          Icons.open_in_new,
          color: Colors.white,
          size: size,
        ),
        onPressed: isEnabled ? () => openPopup(context) : () {},
      ),
    );
  }

  void openPopup(BuildContext context) {
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => PopOverVideoPlayerOverlay(
        videoUrl: videoUrl!,
        playerFactory: playerFactory,
        onClose: () => entry.remove(),
        isMobile: isMobile,
      ),
    );

    Overlay.of(context).insert(entry);
  }
}
