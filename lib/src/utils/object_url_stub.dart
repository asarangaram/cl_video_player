/// Web only: fetches [url] with [headers] and returns an object URL for the
/// downloaded file. Native players send headers themselves, so this is never
/// called off the web.
Future<String> fetchAsObjectUrl(
  String url,
  Map<String, String> headers,
) async {
  throw UnsupportedError('fetchAsObjectUrl is only available on web.');
}

/// Web only: releases an object URL from [fetchAsObjectUrl].
void revokeObjectUrl(String objectUrl) {
  throw UnsupportedError('revokeObjectUrl is only available on web.');
}
