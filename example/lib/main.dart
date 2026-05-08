import 'package:cl_video_player/cl_video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'uploader_demo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const VideoPlayerExampleApp());
}

class VideoPlayerExampleApp extends StatelessWidget {
  const VideoPlayerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const VideoPlayerTestScreen(),
    );
  }
}

class VideoPlayerTestScreen extends StatefulWidget {
  const VideoPlayerTestScreen({super.key});

  @override
  State<VideoPlayerTestScreen> createState() => VideoPlayerTestScreenState();
}

class VideoPlayerTestScreenState extends State<VideoPlayerTestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Source selection
  bool _isNetworkSource = true;
  final TextEditingController _urlController = TextEditingController(
    text: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  );
  String? _selectedFilePath;

  // Comments for each tab
  final List<TextEditingController> _commentControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  // Players
  VideoPlayerInterface? _nativePlayer;
  VideoPlayerInterface? _mediaKitPlayer;
  VideoPlayerInterface? _htmlPlayer;
  VideoPlayerInterface? _overlayPlayer;

  // Player states
  final Map<int, PlayerState> _playerStates = {
    0: PlayerState(),
    1: PlayerState(),
    2: PlayerState(),
    3: PlayerState(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Set default comments
    _commentControllers[0].text =
        'NativeVideoPlayer uses Flutter\'s video_player package.\n'
        'Works on all platforms.\n'
        'Set applySafariFirstFrameFix=true for Safari.';
    _commentControllers[1].text =
        'MediaKitVideoPlayer uses texture-based rendering.\n'
        'Best for desktop and Android.\n'
        'Requires MediaKit.ensureInitialized() at startup.';
    _commentControllers[2].text =
        'HtmlVideoPlayer uses native HTML5 <video> element.\n'
        'Web-only implementation.\n'
        'Bypasses Flutter\'s canvas rendering.';
    _commentControllers[3].text =
        'OverlayVideoPlayer renders outside Flutter\'s widget tree.\n'
        'Web-only, best for Safari compatibility.\n'
        'Bypasses platform view positioning bugs.';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    for (final controller in _commentControllers) {
      controller.dispose();
    }
    _disposeAllPlayers();
    super.dispose();
  }

  void _disposeAllPlayers() {
    _nativePlayer?.dispose();
    _mediaKitPlayer?.dispose();
    _htmlPlayer?.dispose();
    _overlayPlayer?.dispose();
    _nativePlayer = null;
    _mediaKitPlayer = null;
    _htmlPlayer = null;
    _overlayPlayer = null;
  }

  String get _currentSource {
    if (_isNetworkSource) {
      return _urlController.text.trim();
    } else {
      return _selectedFilePath ?? '';
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFilePath = result.files.first.path ?? result.files.first.name;
      });
    }
  }

  Future<void> _loadVideo() async {
    final source = _currentSource;
    if (source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a URL or select a file')),
      );
      return;
    }

    _disposeAllPlayers();

    // Reset all player states
    for (final state in _playerStates.values) {
      state.reset();
    }
    setState(() {});

    // Initialize players based on current tab
    await _initializePlayerForTab(_tabController.index, source);
  }

  Future<void> _initializePlayerForTab(int tabIndex, String source) async {
    final state = _playerStates[tabIndex]!;

    try {
      state.isLoading = true;
      setState(() {});

      VideoPlayerInterface player;
      switch (tabIndex) {
        case 0:
          player = NativeVideoPlayer(applySafariFirstFrameFix: !kIsWeb);
          _nativePlayer = player;
          break;
        case 1:
          player = MediaKitVideoPlayer();
          _mediaKitPlayer = player;
          break;
        case 2:
          if (!kIsWeb) {
            state.error = 'HtmlVideoPlayer is web-only';
            state.isLoading = false;
            setState(() {});
            return;
          }
          player = HtmlVideoPlayer();
          _htmlPlayer = player;
          break;
        case 3:
          if (!kIsWeb) {
            state.error = 'OverlayVideoPlayer is web-only';
            state.isLoading = false;
            setState(() {});
            return;
          }
          player = OverlayVideoPlayer();
          _overlayPlayer = player;
          break;
        default:
          return;
      }

      await player.initialize(
        onPlayingChanged: (isPlaying) {
          state.isPlaying = isPlaying;
          setState(() {});
        },
        onPositionChanged: (position) {
          state.position = position;
          setState(() {});
        },
        onDurationChanged: (duration) {
          state.duration = duration;
          setState(() {});
        },
        onError: (error) {
          state.error = error.toString();
          setState(() {});
        },
      );

      await player.open(source);

      state.isLoading = false;
      state.isInitialized = true;
      setState(() {});
    } catch (e) {
      state.isLoading = false;
      state.error = e.toString();
      setState(() {});
    }
  }

  VideoPlayerInterface? _getPlayerForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _nativePlayer;
      case 1:
        return _mediaKitPlayer;
      case 2:
        return _htmlPlayer;
      case 3:
        return _overlayPlayer;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player Test'),
        actions: [
          IconButton(
            tooltip: 'Open uploader demo',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const UploaderDemoScreen(),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            // Initialize player for this tab if video is loaded but player isn't
            final source = _currentSource;
            if (source.isNotEmpty && _getPlayerForTab(index) == null) {
              _initializePlayerForTab(index, source);
            }
          },
          tabs: const [
            Tab(text: 'Native'),
            Tab(text: 'MediaKit'),
            Tab(text: 'HTML'),
            Tab(text: 'Overlay'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Source selection section
          _buildSourceSection(),
          const Divider(),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlayerTab(0, 'NativeVideoPlayer'),
                _buildPlayerTab(1, 'MediaKitVideoPlayer'),
                _buildPlayerTab(2, 'HtmlVideoPlayer'),
                _buildPlayerTab(3, 'OverlayVideoPlayer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Network / File toggle
          Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Network')),
                  ButtonSegment(value: false, label: Text('File')),
                ],
                selected: {_isNetworkSource},
                onSelectionChanged: (values) {
                  setState(() {
                    _isNetworkSource = values.first;
                  });
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isNetworkSource
                    ? TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Video URL',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedFilePath ?? 'No file selected',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _pickFile,
                            child: const Text('Browse'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _loadVideo,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Load'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTab(int tabIndex, String playerName) {
    final state = _playerStates[tabIndex]!;
    final player = _getPlayerForTab(tabIndex);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Player widget
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildPlayerWidget(player, state),
            ),
          ),
          const SizedBox(height: 16),
          // Controls
          _buildControls(player, state),
          const SizedBox(height: 16),
          // Status info
          _buildStatusInfo(state, playerName),
          const SizedBox(height: 16),
          // Comments text box
          Expanded(
            flex: 1,
            child: TextField(
              controller: _commentControllers[tabIndex],
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes / Expected Behavior',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                hintText: 'Add your observations here...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerWidget(VideoPlayerInterface? player, PlayerState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error: ${state.error}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (player == null || !state.isInitialized) {
      return const Center(
        child: Text(
          'Press Load to start',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: player.buildVideoWidget(),
    );
  }

  Widget _buildControls(VideoPlayerInterface? player, PlayerState state) {
    final isEnabled = player != null && state.isInitialized;

    return Column(
      children: [
        // Seek slider
        Row(
          children: [
            Text(_formatDuration(state.position)),
            Expanded(
              child: Slider(
                value: state.duration.inMilliseconds > 0
                    ? (state.position.inMilliseconds /
                            state.duration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0,
                onChanged: isEnabled
                    ? (value) {
                        final position = Duration(
                          milliseconds:
                              (value * state.duration.inMilliseconds).toInt(),
                        );
                        player.seekTo(position);
                      }
                    : null,
              ),
            ),
            Text(_formatDuration(state.duration)),
          ],
        ),
        // Play/pause and volume
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 48,
              onPressed: isEnabled
                  ? () {
                      if (state.isPlaying) {
                        player.pause();
                      } else {
                        player.play();
                      }
                    }
                  : null,
            ),
            const SizedBox(width: 32),
            const Icon(Icons.volume_up),
            SizedBox(
              width: 120,
              child: Slider(
                value: state.volume,
                onChanged: isEnabled
                    ? (value) {
                        state.volume = value;
                        player.setVolume(value);
                        setState(() {});
                      }
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusInfo(PlayerState state, String playerName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildStatusItem('Player', playerName),
          _buildStatusItem('Initialized', state.isInitialized ? 'Yes' : 'No'),
          _buildStatusItem('Playing', state.isPlaying ? 'Yes' : 'No'),
          _buildStatusItem(
            'Duration',
            _formatDuration(state.duration),
          ),
          if (state.error != null)
            Expanded(
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class PlayerState {
  bool isLoading = false;
  bool isInitialized = false;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double volume = 1.0;
  String? error;

  void reset() {
    isLoading = false;
    isInitialized = false;
    isPlaying = false;
    position = Duration.zero;
    duration = Duration.zero;
    error = null;
  }
}
