import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for highlight media playback controls.
///
/// Combines audio mute and playback paused into a single state object.
/// - [isMuted]: when true, video players set volume to 0. Defaults to true
///   for autoplay compliance.
/// - [isPaused]: when true, video players pause and animated images freeze.
///   Defaults to false (playing).
@immutable
class MediaControlState {
  const MediaControlState({
    this.isMuted = true,
    this.isPaused = false,
  });

  final bool isMuted;
  final bool isPaused;

  MediaControlState copyWith({
    bool? isMuted,
    bool? isPaused,
  }) {
    return MediaControlState(
      isMuted: isMuted ?? this.isMuted,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaControlState &&
          other.isMuted == isMuted &&
          other.isPaused == isPaused;

  @override
  int get hashCode => Object.hash(isMuted, isPaused);

  @override
  String toString() =>
      'MediaControlState(isMuted: $isMuted, isPaused: $isPaused)';
}

class MediaControlNotifier extends Notifier<MediaControlState> {
  @override
  MediaControlState build() => const MediaControlState();

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void setMuted({required bool muted}) {
    state = state.copyWith(isMuted: muted);
  }

  void setPaused({required bool paused}) {
    state = state.copyWith(isPaused: paused);
  }
}

/// Global media control state for highlight media players.
///
/// Provides both audio mute and playback pause controls.
final mediaControlProvider =
    NotifierProvider<MediaControlNotifier, MediaControlState>(
  MediaControlNotifier.new,
);
