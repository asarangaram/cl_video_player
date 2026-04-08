/// Video player implementations for experimentation and testing.
///
/// This package provides 4 independent video player implementations:
/// - [NativeVideoPlayer] - Flutter's official video_player package
/// - [MediaKitVideoPlayer] - media_kit for texture-based rendering
/// - [HtmlVideoPlayer] - HTML5 video element (web only)
/// - [OverlayVideoPlayer] - Overlay video outside Flutter (web only)
///
/// All players implement [VideoPlayerInterface] for easy swapping.
library cl_video_player;

export 'src/video_player_interface.dart';
export 'src/video_player_native.dart';
export 'src/video_player_media_kit.dart';
export 'src/video_player_html.dart';
export 'src/video_player_overlay.dart';
