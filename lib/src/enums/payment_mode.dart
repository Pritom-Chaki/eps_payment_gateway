/// Payment mode for [EpsPaymentGateway].
///
/// - [direct]: Flutter calls the EPS InitializeEPS API directly using
///   merchant credentials. The existing flow, unchanged.
/// - [server]: Flutter calls your backend which in turn calls InitializeEPS.
///   The backend returns a redirect_url that the package opens in a WebView.
enum EPSMode {
  /// Current implementation — Flutter calls EPS APIs directly.
  direct,

  /// Backend-initiated — Flutter calls your server, which proxies to EPS.
  server,
}
