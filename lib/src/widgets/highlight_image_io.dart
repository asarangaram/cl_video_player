import 'dart:io';

import 'package:flutter/material.dart';

/// Builds an image widget from a file path (native platforms only)
Widget buildFileImage(
  String uri,
  BoxFit fit,
  Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
) {
  return Image.file(
    File(uri),
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: errorBuilder,
  );
}
