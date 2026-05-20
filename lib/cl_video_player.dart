/// Video player implementations and gallery widgets.
///
/// Players:
/// - `NativeVideoPlayer` - Flutter's official video_player package
/// - `MediaKitVideoPlayer` - media_kit for texture-based rendering
/// - `HtmlVideoPlayer` - HTML5 video element (web only)
/// - `OverlayVideoPlayer` - Overlay video outside Flutter (web only)
///
/// Gallery:
/// - `GalleryDesktop` - Desktop gallery with nav buttons and auto-scroll
/// - `GalleryMobile` - Mobile gallery with PageView and thumbnail strip
/// - `GalleryVideoPlayer` - Video player with poster preview
/// - `GalleryItem` - Gallery item model
library;

export 'src/gallery_desktop.dart';
// Gallery
export 'src/gallery_item.dart';
export 'src/gallery_mobile.dart';
export 'src/gallery_navigation_button.dart';
export 'src/gallery_pdf_card.dart';
export 'src/gallery_thumbnail_strip.dart';
export 'src/gallery_video_player.dart';
// Providers
export 'src/providers/media_control.dart';
// Uploader
export 'src/uploader/file_picker_adapter.dart'
    show FilePickerAdapter, PickedMedia, defaultFilePicker;
export 'src/uploader/media_upload_types.dart';
export 'src/uploader/media_uploader.dart';
// Web-only players — guarded with conditional exports
export 'src/video_player_html_stub.dart'
    if (dart.library.js_interop) 'src/video_player_html.dart';
// Players
export 'src/video_player_interface.dart';
export 'src/video_player_media_kit.dart';
export 'src/video_player_native.dart';
export 'src/video_player_overlay_stub.dart'
    if (dart.library.js_interop) 'src/video_player_overlay.dart';
// Utils
export 'src/video_url_utils.dart';
export 'src/widgets/audio_controller_audio_mute.dart';
export 'src/widgets/highlight_image.dart';
// Highlight widgets
export 'src/widgets/highlight_media.dart';
export 'src/widgets/pop_over_video_player.dart';
