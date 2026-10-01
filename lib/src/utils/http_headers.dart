/// The headers to give `Image.network`: null when there are none, so a load
/// without headers is exactly the load it was before headers existed.
Map<String, String>? imageRequestHeaders(Map<String, String> headers) =>
    headers.isEmpty ? null : headers;
