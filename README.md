# cl_video_player

Video player implementations for experimentation and testing. Provides 4 independent player types that implement a common interface.

## Usage

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  cl_video_player:
    path: ../cl_video_player  # or your path
```

### Import

```dart
// Import all players
import 'package:cl_video_player/cl_video_player.dart';

// Or import individual players
import 'package:cl_video_player/src/video_player_native.dart';
import 'package:cl_video_player/src/video_player_media_kit.dart';
import 'package:cl_video_player/src/video_player_html.dart';
import 'package:cl_video_player/src/video_player_overlay.dart';
```

### Basic Usage

All players implement `VideoPlayerInterface`:

```dart
// Create a player
final player = NativeVideoPlayer();

// Initialize with callbacks
await player.initialize(
  onPlayingChanged: (isPlaying) => print('Playing: $isPlaying'),
  onPositionChanged: (position) => print('Position: $position'),
  onDurationChanged: (duration) => print('Duration: $duration'),
  onError: (error) => print('Error: $error'),
);

// Load and play video
await player.open('https://example.com/video.mp4');

// Control playback
await player.play();
await player.pause();
await player.seekTo(Duration(seconds: 30));
await player.setVolume(0.5);  // 0.0 to 1.0

// Build widget
Widget videoWidget = player.buildVideoWidget(
  fit: BoxFit.contain,
  showControls: false,
);

// Dispose when done
player.dispose();
```

### Platform Considerations

| Player | iOS | Android | Web (Chrome) | Web (Safari) | Desktop |
|--------|-----|---------|--------------|--------------|---------|
| NativeVideoPlayer | Yes | Yes | Yes | Yes* | Yes |
| MediaKitVideoPlayer | Yes | Yes | Limited | Limited | Yes |
| HtmlVideoPlayer | No | No | Yes | Yes | No |
| OverlayVideoPlayer | No | No | Yes | Yes | No |

\* Set `applySafariFirstFrameFix: true` for Safari

---

## Player Designs

### 1. NativeVideoPlayer

**Package:** `video_player` (Flutter official)

**How it works:**
- Uses Flutter's official `video_player` package
- Renders video through platform views on mobile, HTML video on web
- Provides basic playback controls through the video_player API

**When to use:**
- Cross-platform apps that need to work everywhere
- When you want official Flutter team support
- Simple video playback needs

**Configuration:**
```dart
NativeVideoPlayer(
  applySafariFirstFrameFix: true,  // Appends #t=0.001 to URLs for Safari
)
```

**Safari First Frame Fix:**
Safari has a bug where the first frame often doesn't load. Setting `applySafariFirstFrameFix: true` appends `#t=0.001` to video URLs, forcing Safari to seek and render the first frame.

---

### 2. MediaKitVideoPlayer

**Package:** `media_kit`

**How it works:**
- Uses libmpv under the hood for video decoding
- Renders to a Flutter texture (not a platform view)
- Full control over playback with extensive API

**When to use:**
- Desktop applications (Windows, macOS, Linux)
- Android apps requiring advanced video features
- When you need proper widget compositing (AnimatedSwitcher, overlays)
- When platform views cause z-ordering issues

**Setup required:**
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();  // Required!
  runApp(MyApp());
}
```

**Advantages:**
- Texture-based rendering works with Flutter's compositor
- AnimatedSwitcher crossfades work correctly
- No z-ordering issues with overlays
- Extensive codec support

**Limitations:**
- Web support is limited (works in some browsers)
- Larger binary size due to native libraries

---

### 3. HtmlVideoPlayer

**Package:** `web` (Dart web APIs)

**How it works:**
- Creates a native HTML5 `<video>` element
- Embeds it using `HtmlElementView` platform view
- Video rendering is handled entirely by the browser

**When to use:**
- Web-only applications
- When you need native browser video features
- When Flutter's canvas rendering causes issues
- For better hardware acceleration on web

**Advantages:**
- Native browser video playback
- Hardware acceleration handled by browser
- Better Safari compatibility than canvas-based rendering
- Supports all browser-native video features

**Limitations:**
- Web only (will not compile on mobile/desktop)
- Platform view limitations apply (z-ordering with Flutter widgets)
- May have sizing issues with Flutter's layout system

**Technical details:**
- Registers a unique `platformViewRegistry` for each instance
- Automatically fixes parent element sizing for proper display
- Includes extensive debug logging in debug mode

---

### 4. OverlayVideoPlayer

**Package:** `web` (Dart web APIs)

**How it works:**
- Creates video element directly in the DOM body (outside Flutter)
- Uses `position: fixed` to overlay on top of Flutter canvas
- A placeholder widget tracks position and syncs the overlay

**When to use:**
- Safari web apps with platform view positioning bugs
- When `HtmlVideoPlayer` has positioning issues
- When you need video to overlay Flutter content reliably

**Advantages:**
- Bypasses Flutter's platform view system entirely
- No positioning bugs on Safari
- Native browser controls work properly
- Smooth scrolling synchronization

**Limitations:**
- Web only
- Video is outside Flutter's widget tree (some interactions may differ)
- Requires position syncing which runs every frame
- z-index is hardcoded to 1000

**Technical details:**
- Creates a container `<div>` with `position: fixed`
- Updates position every 16ms (60fps) to match Flutter placeholder
- Automatically hides when scrolled out of viewport
- Muted by default for Safari autoplay compliance, unmutes after playback starts

---

## Running the Example

```bash
cd cl_video_player/example
flutter pub get
flutter run -d chrome  # For web
flutter run -d macos   # For macOS
```

The example app provides:
- Network URL or file picker for video source
- 4 tabs to test each player implementation
- Playback controls (play/pause, seek, volume)
- Status info display
- Comments text box to document observations

---

## Architecture

Each player implementation is completely independent:
- Only imports the shared `VideoPlayerInterface`
- No cross-dependencies between player files
- Removing one player file doesn't affect others

```
lib/
├── cl_video_player.dart           # Barrel file
└── src/
    ├── video_player_interface.dart  # Shared interface
    ├── video_player_native.dart     # video_player package
    ├── video_player_media_kit.dart  # media_kit package
    ├── video_player_html.dart       # HTML5 video (web)
    └── video_player_overlay.dart    # Overlay video (web)
```
