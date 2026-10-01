import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Fetches [url] with [headers] and returns an object (`blob:`) URL for the
/// downloaded file.
///
/// An HTML `<video>` element cannot send request headers, so a video that
/// needs them is downloaded in full first and played from memory. Release
/// the result with [revokeObjectUrl] when the player is done with it.
Future<String> fetchAsObjectUrl(
  String url,
  Map<String, String> headers,
) async {
  final requestHeaders = web.Headers();
  for (final MapEntry(:key, :value) in headers.entries) {
    requestHeaders.append(key, value);
  }

  final response = await web.window
      .fetch(url.toJS, web.RequestInit(headers: requestHeaders))
      .toDart;
  if (!response.ok) {
    throw Exception('Fetching $url failed with HTTP ${response.status}.');
  }

  final blob = await response.blob().toDart;
  return web.URL.createObjectURL(blob);
}

/// Releases an object URL from [fetchAsObjectUrl].
void revokeObjectUrl(String objectUrl) => web.URL.revokeObjectURL(objectUrl);
