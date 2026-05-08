import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'media_upload_types.dart';
import 'upload_item_state.dart';

/// Row used inside both single and multi upload dialogs.
///
/// Renders a fixed-height thumbnail (image preview for `MediaKind.image`,
/// icons for video / pdf), the filename, and a phase indicator.
class UploadItemTile extends StatelessWidget {
  const UploadItemTile({required this.item, super.key});

  final UploadItemState item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: buildThumbnail(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                buildPhaseLine(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildThumbnail(BuildContext context) {
    if (item.kind == MediaKind.image) {
      return Image.memory(
        Uint8List.fromList(item.bytes),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    final IconData icon = item.kind == MediaKind.video
        ? Icons.videocam_outlined
        : Icons.picture_as_pdf_outlined;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 28,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget buildPhaseLine(BuildContext context) {
    final theme = Theme.of(context);
    final (label, leading) = switch (item.phase) {
      UploadItemPhase.queued => (
        'Queued',
        const Icon(Icons.schedule, size: 14),
      ),
      UploadItemPhase.uploading => (
        'Uploading…',
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      UploadItemPhase.converting => (
        'Converting…',
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      UploadItemPhase.completed => (
        'Done',
        Icon(
          Icons.check_circle_outline,
          size: 14,
          color: theme.colorScheme.primary,
        ),
      ),
      UploadItemPhase.failed => (
        item.error == null ? 'Failed' : 'Failed: ${item.error}',
        Icon(
          Icons.error_outline,
          size: 14,
          color: theme.colorScheme.error,
        ),
      ),
      UploadItemPhase.cancelled => (
        'Cancelled',
        const Icon(Icons.block, size: 14),
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
