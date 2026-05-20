import 'package:cl_video_player/cl_video_player.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const UploadExampleApp());
}

class UploadExampleApp extends StatelessWidget {
  const UploadExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaUploader demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const UploaderDemoScreen(),
    );
  }
}

/// Exercises [MediaUploader] with a fake (in-memory) upload + status
/// backend. No SDK / network involved.
///
/// Image and pdf uploads complete synchronously. Video uploads return
/// `processing` and the fake polls converge to `completed` after 2
/// ticks. Filenames starting with `fail` always fail.
class UploaderDemoScreen extends StatefulWidget {
  const UploaderDemoScreen({super.key});

  @override
  State<UploaderDemoScreen> createState() => UploaderDemoScreenState();
}

class UploaderDemoScreenState extends State<UploaderDemoScreen> {
  final FakeUploadBackend backend = FakeUploadBackend();
  final List<String> log = [];

  void appendLog(String line) {
    setState(() => log.insert(0, line));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MediaUploader demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                MediaUploader(
                  mode: MediaUploaderMode.single,
                  uploadCallback: backend.upload,
                  statusCallback: backend.status,
                  onComplete: (results) {
                    for (final r in results) {
                      appendLog('SINGLE done: ${r.uuid} → ${r.downloadUrl}');
                    }
                  },
                  triggerBuilder: (_, openPicker) => FilledButton.icon(
                    onPressed: openPicker,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload single'),
                  ),
                ),
                MediaUploader(
                  mode: MediaUploaderMode.multi,
                  uploadCallback: backend.upload,
                  statusCallback: backend.status,
                  onComplete: (results) {
                    appendLog('MULTI done: ${results.length} files');
                    for (final r in results) {
                      appendLog('  • ${r.uuid}');
                    }
                  },
                  triggerBuilder: (_, openPicker) => FilledButton.icon(
                    onPressed: openPicker,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload multiple'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: pick a file named "fail*" to exercise the failure path.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: log.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log[i],
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FakeUploadBackend {
  int nextId = 1;
  final Map<int, FakeRecord> records = {};

  Future<MediaUploadResult> upload(MediaUploadRequest req) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final id = nextId++;
    final uuid = 'fake-$id';
    final downloadUrl = 'memory://$uuid/${req.filename}';
    final isFail = req.filename.toLowerCase().startsWith('fail');
    if (isFail) {
      return MediaUploadResult(
        id: id,
        uuid: uuid,
        kind: req.kind,
        status: MediaConversionStatus.failed,
        downloadUrl: downloadUrl,
        error: 'Forced failure (fake)',
      );
    }
    if (req.kind == MediaKind.video) {
      records[id] = FakeRecord(
        result: MediaUploadResult(
          id: id,
          uuid: uuid,
          kind: req.kind,
          status: MediaConversionStatus.processing,
          downloadUrl: downloadUrl,
        ),
        ticksRemaining: 2,
      );
      return records[id]!.result;
    }
    return MediaUploadResult(
      id: id,
      uuid: uuid,
      kind: req.kind,
      status: MediaConversionStatus.completed,
      downloadUrl: downloadUrl,
    );
  }

  Future<MediaUploadResult> status(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final rec = records[id];
    if (rec == null) {
      throw StateError('Unknown id: $id');
    }
    if (rec.ticksRemaining > 0) {
      rec.ticksRemaining--;
      return rec.result;
    }
    return rec.result =
        rec.result.copyWith(status: MediaConversionStatus.completed);
  }
}

class FakeRecord {
  FakeRecord({required this.result, required this.ticksRemaining});
  MediaUploadResult result;
  int ticksRemaining;
}
