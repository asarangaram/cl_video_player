import 'package:flutter/material.dart';

/// File images are not supported on web - return error widget
Widget buildFileImage(
  String uri,
  BoxFit fit,
  Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
) {
  return Builder(
    builder: (context) => errorBuilder(
      context,
      UnsupportedError('File images not supported on web: $uri'),
      null,
    ),
  );
}
