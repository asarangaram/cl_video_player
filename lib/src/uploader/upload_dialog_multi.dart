import 'dart:async';

import 'package:flutter/material.dart';

import 'file_picker_adapter.dart';
import 'media_upload_types.dart';
import 'upload_item_state.dart';
import 'upload_item_tile.dart';

/// Multi-file upload modal. Drives picked items serially through
/// queued → uploading → (converting) → completed / failed, then
/// awaits the user pressing Done to return the successful results.
class UploadDialogMulti extends StatefulWidget {
  const UploadDialogMulti({
    required this.picked,
    required this.uploadCallback,
    required this.statusCallback,
    required this.usageContext,
    required this.pollInterval,
    required this.pollTimeout,
    super.key,
  });

  final List<PickedMedia> picked;
  final MediaUploadCallback uploadCallback;
  final MediaStatusCallback statusCallback;
  final String? usageContext;
  final Duration pollInterval;
  final Duration pollTimeout;

  @override
  State<UploadDialogMulti> createState() => UploadDialogMultiState();
}

class UploadDialogMultiState extends State<UploadDialogMulti> {
  late List<UploadItemState> _items;
  late List<GlobalKey> _itemKeys;
  bool _running = false;
  bool _cancelRequested = false;

  @override
  void initState() {
    super.initState();
    _items = [
      for (var i = 0; i < widget.picked.length; i++)
        UploadItemState(
          localId: 'item_$i',
          filename: widget.picked[i].filename,
          bytes: widget.picked[i].bytes,
          kind: widget.picked[i].kind,
          mimeType: widget.picked[i].mimeType,
          phase: UploadItemPhase.queued,
        ),
    ];
    _itemKeys = [for (final _ in _items) GlobalKey()];
    WidgetsBinding.instance.addPostFrameCallback((_) => runQueue());
  }

  void scrollItemIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _itemKeys[index].currentContext;
      if (ctx == null) return;
      unawaited(
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  Future<void> runQueue() async {
    if (_running) return;
    _running = true;
    for (var i = 0; i < _items.length; i++) {
      if (_cancelRequested) {
        markCancelledFrom(i);
        break;
      }
      await processItem(i);
    }
    _running = false;
    if (mounted) setState(() {});
  }

  Future<void> processItem(int index) async {
    updateItem(index, (s) => s.copyWith(phase: UploadItemPhase.uploading));
    scrollItemIntoView(index);
    final src = _items[index];
    try {
      final result = await widget.uploadCallback(
        MediaUploadRequest(
          bytes: src.bytes,
          filename: src.filename,
          kind: src.kind,
          mimeType: src.mimeType,
          usageContext: widget.usageContext,
        ),
      );
      switch (result.status) {
        case MediaConversionStatus.completed:
          updateItem(
            index,
            (s) => s.copyWith(
              phase: UploadItemPhase.completed,
              result: () => result,
            ),
          );
        case MediaConversionStatus.failed:
          updateItem(
            index,
            (s) => s.copyWith(
              phase: UploadItemPhase.failed,
              error: () => result.error ?? 'Upload failed',
            ),
          );
        case MediaConversionStatus.pending:
        case MediaConversionStatus.processing:
          updateItem(
            index,
            (s) => s.copyWith(
              phase: UploadItemPhase.converting,
              result: () => result,
            ),
          );
          await pollUntilTerminal(index, result.id);
      }
    } on Object catch (e) {
      updateItem(
        index,
        (s) => s.copyWith(
          phase: UploadItemPhase.failed,
          error: e.toString,
        ),
      );
    }
  }

  Future<void> pollUntilTerminal(int index, int id) async {
    final deadline = DateTime.now().add(widget.pollTimeout);
    while (mounted && !_cancelRequested) {
      await Future<void>.delayed(widget.pollInterval);
      if (DateTime.now().isAfter(deadline)) {
        updateItem(
          index,
          (s) => s.copyWith(
            phase: UploadItemPhase.failed,
            error: () => 'Conversion timed out',
          ),
        );
        return;
      }
      try {
        final r = await widget.statusCallback(id);
        if (r.status == MediaConversionStatus.completed) {
          updateItem(
            index,
            (s) => s.copyWith(
              phase: UploadItemPhase.completed,
              result: () => r,
            ),
          );
          return;
        }
        if (r.status == MediaConversionStatus.failed) {
          updateItem(
            index,
            (s) => s.copyWith(
              phase: UploadItemPhase.failed,
              error: () => r.error ?? 'Conversion failed',
            ),
          );
          return;
        }
      } on Object catch (e) {
        updateItem(
          index,
          (s) => s.copyWith(
            phase: UploadItemPhase.failed,
            error: e.toString,
          ),
        );
        return;
      }
    }
  }

  void updateItem(
    int index,
    UploadItemState Function(UploadItemState) update,
  ) {
    if (!mounted) return;
    setState(() {
      _items = [
        for (var i = 0; i < _items.length; i++)
          if (i == index) update(_items[i]) else _items[i],
      ];
    });
  }

  void markCancelledFrom(int startIndex) {
    setState(() {
      _items = [
        for (var i = 0; i < _items.length; i++)
          if (i >= startIndex && !_items[i].phase.isTerminal)
            _items[i].copyWith(phase: UploadItemPhase.cancelled)
          else
            _items[i],
      ];
    });
  }

  void requestCancel() {
    setState(() => _cancelRequested = true);
    if (!_running) {
      Navigator.of(context).pop(<MediaUploadResult>[]);
    }
  }

  void confirmDone() {
    Navigator.of(context).pop(successfulResults(_items));
  }

  @override
  Widget build(BuildContext context) {
    final doneEnabled = isDoneEnabled(_items);
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Uploading ${_items.length} file'
                  '${_items.length == 1 ? '' : 's'}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _items.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        KeyedSubtree(
                          key: _itemKeys[i],
                          child: UploadItemTile(item: _items[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _cancelRequested ? null : requestCancel,
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: doneEnabled ? confirmDone : null,
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
