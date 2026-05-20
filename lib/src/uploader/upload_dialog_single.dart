import 'dart:async';

import 'package:flutter/material.dart';

import 'file_picker_adapter.dart';
import 'media_upload_types.dart';
import 'upload_item_state.dart';
import 'upload_item_tile.dart';

/// Centered modal that uploads one file and (for video) polls until
/// the server reports a terminal conversion status.
///
/// Returns the [MediaUploadResult] on success, or `null` on failure /
/// cancel — the caller decides whether to surface a toast.
class UploadDialogSingle extends StatefulWidget {
  const UploadDialogSingle({
    required this.picked,
    required this.uploadCallback,
    required this.statusCallback,
    required this.usageContext,
    required this.pollInterval,
    required this.pollTimeout,
    super.key,
  });

  final PickedMedia picked;
  final MediaUploadCallback uploadCallback;
  final MediaStatusCallback statusCallback;
  final String? usageContext;
  final Duration pollInterval;
  final Duration pollTimeout;

  @override
  State<UploadDialogSingle> createState() => UploadDialogSingleState();
}

class UploadDialogSingleState extends State<UploadDialogSingle> {
  late UploadItemState _item;
  Timer? _pollTimer;
  Timer? _timeoutTimer;
  bool _closed = false;
  MediaUploadResult? _outcome;

  @override
  void initState() {
    super.initState();
    _item = UploadItemState(
      localId: 'single',
      filename: widget.picked.filename,
      bytes: widget.picked.bytes,
      kind: widget.picked.kind,
      mimeType: widget.picked.mimeType,
      phase: UploadItemPhase.uploading,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => runUpload());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> runUpload() async {
    try {
      final result = await widget.uploadCallback(
        MediaUploadRequest(
          bytes: widget.picked.bytes,
          filename: widget.picked.filename,
          kind: widget.picked.kind,
          mimeType: widget.picked.mimeType,
          usageContext: widget.usageContext,
        ),
      );
      handleResult(result);
    } on Object catch (e) {
      failWith(e.toString());
    }
  }

  void handleResult(MediaUploadResult result) {
    if (!mounted) return;
    switch (result.status) {
      case MediaConversionStatus.completed:
        finishWith(result);
      case MediaConversionStatus.failed:
        failWith(result.error ?? 'Upload failed');
      case MediaConversionStatus.pending:
      case MediaConversionStatus.processing:
        setState(() {
          _item = _item.copyWith(
            phase: UploadItemPhase.converting,
            result: () => result,
          );
        });
        startPolling(result.id);
    }
  }

  void startPolling(int id) {
    _timeoutTimer = Timer(widget.pollTimeout, () {
      failWith('Conversion timed out');
    });
    _pollTimer = Timer.periodic(widget.pollInterval, (_) async {
      try {
        final r = await widget.statusCallback(id);
        if (!mounted) return;
        if (r.status == MediaConversionStatus.completed) {
          finishWith(r);
        } else if (r.status == MediaConversionStatus.failed) {
          failWith(r.error ?? 'Conversion failed');
        }
      } on Object catch (e) {
        failWith(e.toString());
      }
    });
  }

  void finishWith(MediaUploadResult result) {
    if (_closed) return;
    _closed = true;
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    _outcome = result;
    Navigator.of(context).pop(result);
  }

  void failWith(String error) {
    if (_closed) return;
    _closed = true;
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    final base = _outcome ??
        MediaUploadResult(
          id: -1,
          uuid: '',
          kind: widget.picked.kind,
          status: MediaConversionStatus.failed,
          downloadUrl: '',
          error: error,
        );
    final failed = base.copyWith(
      status: MediaConversionStatus.failed,
      error: () => error,
    );
    if (mounted) {
      setState(() {
        _item = _item.copyWith(
          phase: UploadItemPhase.failed,
          error: () => error,
        );
      });
      // Give the user a beat to see the failure, then close with the
      // failed result so the host can surface a toast.
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.of(context).pop(failed);
      });
    }
  }

  void cancel() {
    if (_closed) return;
    _closed = true;
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    Navigator.of(context).pop(_outcome);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Uploading',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              UploadItemTile(item: _item),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _closed ? null : cancel,
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
