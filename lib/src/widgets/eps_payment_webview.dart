import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../internal/eps_callback_urls.dart';

/// URLs that signal the end of the payment flow in **server mode**.
///
/// When the WebView navigates to one of these the payment is considered
/// complete and [onResult] is called with the intercepted URL.
const _kSuccessUrl = 'https://pixposbd.com/payment/success';
const _kFailUrl = 'https://pixposbd.com/payment/fail';
const _kCancelUrl = 'https://pixposbd.com/payment/cancel';

/// Renders the EPS hosted payment page and intercepts the redirect callback.
///
/// Supports two sets of callback URLs:
/// - Internal callbacks used in **direct mode**
///   ([kEpsSuccessCallbackUrl], [kEpsFailCallbackUrl], [kEpsCancelCallbackUrl]).
/// - Merchant callback URLs used in **server mode**
///   (`https://pixposbd.com/payment/success`, `fail`, `cancel`).
class EpsPaymentWebView extends StatefulWidget {
  const EpsPaymentWebView({
    super.key,
    required this.redirectUrl,
    required this.onResult,
  });

  /// The URL to load (RedirectURL from EPS or backend).
  final String redirectUrl;

  /// Called once when a callback URL is detected.
  /// The argument is the full intercepted URL string.
  final void Function(String callbackUrl) onResult;

  @override
  State<EpsPaymentWebView> createState() => _EpsPaymentWebViewState();
}

class _EpsPaymentWebViewState extends State<EpsPaymentWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resultHandled = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _loading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;

            if (_resultHandled) return NavigationDecision.prevent;

            for (final callback in [
              kEpsSuccessCallbackUrl,
              kEpsFailCallbackUrl,
              kEpsCancelCallbackUrl,
              _kSuccessUrl,
              _kFailUrl,
              _kCancelUrl,
            ]) {
              if (url.startsWith(callback)) {
                _resultHandled = true;
                widget.onResult(url);
                return NavigationDecision.prevent;
              }
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          const Center(child: CircularProgressIndicator()),
        if (_hasError)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to load payment page.'),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {
                    _hasError = false;
                    _controller.loadRequest(Uri.parse(widget.redirectUrl));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
