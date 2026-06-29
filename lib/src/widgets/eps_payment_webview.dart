import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../internal/eps_callback_urls.dart';

/// Renders the EPS hosted payment page and intercepts the redirect callback.
///
/// When EPS redirects to one of the internal callback URLs
/// ([kEpsSuccessCallbackUrl], [kEpsFailCallbackUrl], [kEpsCancelCallbackUrl]),
/// [onResult] is called with the full URL (including query parameters) and
/// navigation is prevented. Any other URL is loaded normally.
class EpsPaymentWebView extends StatefulWidget {
  const EpsPaymentWebView({
    super.key,
    required this.redirectUrl,
    required this.onResult,
  });

  /// The `RedirectURL` returned by the EPS InitializeEPS endpoint.
  final String redirectUrl;

  /// Called once when EPS redirects to a callback URL.
  /// The argument is the full intercepted URL string.
  final void Function(String callbackUrl) onResult;

  @override
  State<EpsPaymentWebView> createState() => _EpsPaymentWebViewState();
}

class _EpsPaymentWebViewState extends State<EpsPaymentWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resultHandled = false;

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
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (!_resultHandled &&
                (url.startsWith(kEpsSuccessCallbackUrl) ||
                    url.startsWith(kEpsFailCallbackUrl) ||
                    url.startsWith(kEpsCancelCallbackUrl))) {
              _resultHandled = true;
              widget.onResult(url);
              return NavigationDecision.prevent;
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
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
