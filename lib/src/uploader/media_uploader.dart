import 'package:flutter/material.dart';

import 'file_picker_adapter.dart';
import 'media_upload_types.dart';
import 'upload_dialog_multi.dart';
import 'upload_dialog_single.dart';

/// Trigger-builder signature for [MediaUploader].
///
/// The builder is given an [openPicker] callback to wire to whatever
/// tappable widget the host renders (button, icon, card, …).
typedef MediaUploaderTriggerBuilder =
    Widget Function(
      BuildContext context,
      VoidCallback openPicker,
    );

/// SDK-agnostic media uploader entry point.
///
/// Renders a host-supplied trigger via [triggerBuilder]. On tap, opens
/// the platform file picker (constrained by [allowedKinds]) and then a
/// modal popover that drives the upload + conversion-status lifecycle.
///
/// On success, [onComplete] is called with one or more
/// [MediaUploadResult]s (only the successfully completed ones — failed /
/// cancelled items are dropped from the callback payload). On a single-
/// file failure, a [SnackBar] is shown and [onComplete] is not called.
class MediaUploader extends StatelessWidget {
  const MediaUploader({
    required this.mode,
    required this.uploadCallback,
    required this.statusCallback,
    required this.onComplete,
    required this.triggerBuilder,
    this.allowedKinds = const {
      MediaKind.image,
      MediaKind.video,
      MediaKind.pdf,
    },
    this.usageContext,
    this.pickerAdapter = defaultFilePicker,
    this.pollInterval = const Duration(seconds: 2),
    this.pollTimeout = const Duration(minutes: 5),
    super.key,
  });

  final MediaUploaderMode mode;
  final MediaUploadCallback uploadCallback;
  final MediaStatusCallback statusCallback;
  final MediaUploadCompleteCallback onComplete;
  final MediaUploaderTriggerBuilder triggerBuilder;
  final Set<MediaKind> allowedKinds;
  final String? usageContext;
  final FilePickerAdapter pickerAdapter;
  final Duration pollInterval;
  final Duration pollTimeout;

  Future<void> openPicker(BuildContext context) async {
    final picked = await pickerAdapter(
      allowMultiple: mode == MediaUploaderMode.multi,
      allowedKinds: allowedKinds,
    );
    if (picked.isEmpty || !context.mounted) return;
    if (mode == MediaUploaderMode.single) {
      await runSingle(context, picked.first);
    } else {
      await runMulti(context, picked);
    }
  }

  Future<void> runSingle(BuildContext context, PickedMedia file) async {
    final result = await showDialog<MediaUploadResult?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UploadDialogSingle(
        picked: file,
        uploadCallback: uploadCallback,
        statusCallback: statusCallback,
        usageContext: usageContext,
        pollInterval: pollInterval,
        pollTimeout: pollTimeout,
      ),
    );
    if (!context.mounted) return;
    if (result != null && result.status == MediaConversionStatus.completed) {
      onComplete([result]);
    } else if (result != null &&
        result.status == MediaConversionStatus.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Upload failed')),
      );
    }
  }

  Future<void> runMulti(BuildContext context, List<PickedMedia> files) async {
    final results = await showDialog<List<MediaUploadResult>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UploadDialogMulti(
        picked: files,
        uploadCallback: uploadCallback,
        statusCallback: statusCallback,
        usageContext: usageContext,
        pollInterval: pollInterval,
        pollTimeout: pollTimeout,
      ),
    );
    if (results != null && results.isNotEmpty) {
      onComplete(results);
    }
  }

  @override
  Widget build(BuildContext context) {
    return triggerBuilder(context, () => openPicker(context));
  }
}
