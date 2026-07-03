/// Thrown when the backend returns an error or the request fails.
class BackendException implements Exception {
  const BackendException(this.message);

  final String message;

  @override
  String toString() => 'BackendException: $message';
}

/// Thrown when the WebView encounters a loading failure.
class WebViewException implements Exception {
  const WebViewException(this.message);

  final String message;

  @override
  String toString() => 'WebViewException: $message';
}

/// Thrown when an invalid parameter is passed to the API.
class InvalidParameterException implements Exception {
  const InvalidParameterException(this.message);

  final String message;

  @override
  String toString() => 'InvalidParameterException: $message';
}
