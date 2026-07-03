import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api/backend_service.dart';
import 'config/eps_config.dart';
import 'config/eps_display_mode.dart';
import 'enums/payment_mode.dart';
import 'internal/eps_callback_urls.dart';
import 'models/eps_order.dart';
import 'models/eps_payment_result.dart';
import 'models/eps_transaction_status.dart';
import 'models/payment_result.dart';
import 'services/eps_api_service.dart';
import 'services/eps_auth_service.dart';
import 'utils/exceptions.dart';
import 'widgets/eps_payment_webview.dart';

/// Entry point for EPS payment gateway integration.
///
/// Supports two modes:
/// - [EPSMode.direct] — Flutter calls the EPS InitializeEPS API directly
///   using merchant credentials (the original flow).
/// - [EPSMode.server] — Flutter calls a backend endpoint which proxies
///   the request to EPS. The backend returns a `redirect_url` that the
///   package opens in a WebView.
///
/// ## Direct mode (existing API)
///
/// ```dart
/// final eps = EpsPaymentGateway(config: EpsConfig(...));
/// final result = await eps.pay(context: context, order: EpsOrder(...));
/// ```
///
/// ## Server mode (new API)
///
/// ```dart
/// final result = await EpsPaymentGateway.startPayment(
///   mode: EPSMode.server,
///   initUrl: 'https://pixposbd.com/api/eps/init',
///   requestBody: {
///     'invoice_no': 'INV-001',
///     'amount': 500,
///     'customer_name': 'Rahim Uddin',
///     'customer_phone': '01712345678',
///   },
/// );
/// ```
class EpsPaymentGateway {
  EpsPaymentGateway({required EpsConfig config})
      : _config = config,
        _auth = EpsAuthService(config),
        _api = EpsApiService(config);

  final EpsConfig _config;
  final EpsAuthService _auth;
  final EpsApiService _api;

  // ── Public (Direct Mode — static convenience) ──────────────────────────

  /// Convenience static method for **server mode**.
  ///
  /// Call this from anywhere without instantiating [EpsPaymentGateway].
  ///
  /// ```dart
  /// final result = await EpsPaymentGateway.startPayment(
  ///   mode: EPSMode.server,
  ///   initUrl: 'https://pixposbd.com/api/eps/init',
  ///   requestBody: { ... },
  /// );
  /// ```
  static Future<PaymentResult> startPayment({
    required BuildContext context,
    EPSMode mode = EPSMode.server,
    required String initUrl,
    required Map<String, dynamic> requestBody,
    EpsDisplayMode displayMode = EpsDisplayMode.fullScreen,
  }) async {
    final backend = BackendService();
    final initUri = Uri.parse(initUrl);

    try {
      // 1. Call backend to get redirect URL.
      final redirectUrl = await backend.initialize(
        initUrl: initUri,
        requestBody: requestBody,
      );

      if (!context.mounted) {
        return const PaymentResult(
          status: PaymentStatus.cancelled,
          message: 'Context is no longer mounted.',
        );
      }

      // 2. Present payment page and wait for callback.
      final callbackUrl = displayMode == EpsDisplayMode.fullScreen
          ? await _pushFullScreen(context, redirectUrl)
          : await _showBottomSheet(context, redirectUrl);

      // 3. Interpret callback.
      if (callbackUrl == null) {
        return const PaymentResult(
          status: PaymentStatus.cancelled,
          message: 'User closed the payment page.',
        );
      }

      return _resultFromCallback(callbackUrl);
    } on InvalidParameterException catch (e) {
      return PaymentResult(
        status: PaymentStatus.cancelled,
        message: e.message,
      );
    } on BackendException catch (e) {
      return PaymentResult(
        status: PaymentStatus.cancelled,
        message: e.message,
      );
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.cancelled,
        message: e.toString(),
      );
    }
  }

  // ── Public (Direct Mode — instance API) ────────────────────────────────

  /// Launches the EPS payment flow and returns the final [EpsPaymentResult].
  ///
  /// This method:
  /// 1. Obtains a JWT from EPS.
  /// 2. Initialises the transaction and receives a redirect URL.
  /// 3. Presents the EPS payment page (full-screen or modal bottom sheet).
  /// 4. Intercepts the callback redirect.
  /// 5. Verifies the transaction status with EPS.
  ///
  /// Never throws — all failures are returned as [EpsPaymentStatus.error].
  Future<EpsPaymentResult> pay({
    required BuildContext context,
    required EpsOrder order,
    EpsDisplayMode mode = EpsDisplayMode.fullScreen,
  }) async {
    if (kIsWeb && _config.webAuthEndpoint == null) {
      return const EpsPaymentResult(
        status: EpsPaymentStatus.error,
        errorMessage:
            'Web mode requires a same-origin proxy endpoint because EPS does not permit browser-side HTTP requests. Set EpsConfig.webAuthEndpoint to your backend proxy URL.',
      );
    }

    try {
      // 1. Authenticate.
      final token = await _auth.getToken();

      // 2. Generate a stable transaction ID for this session.
      final txnId = order.merchantTransactionId ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // 3. Initialise payment.
      final redirectUrl = await _api.initializePayment(
        token: token,
        order: order,
        merchantTransactionId: txnId,
      );

      if (!context.mounted) {
        return const EpsPaymentResult(
          status: EpsPaymentStatus.error,
          errorMessage: 'Context is no longer mounted.',
        );
      }

      // 4. Present payment page and wait for callback.
      final callbackUrl = mode == EpsDisplayMode.fullScreen
          ? await _pushFullScreen(context, redirectUrl)
          : await _showBottomSheet(context, redirectUrl);

      // 5. Handle cancellation (user closed the sheet without paying).
      if (callbackUrl == null ||
          callbackUrl.startsWith(kEpsCancelCallbackUrl)) {
        return EpsPaymentResult(
          status: EpsPaymentStatus.cancelled,
          merchantTransactionId: txnId,
        );
      }

      // 6. Verify with EPS.
      final statusData = await _api.checkTransactionStatus(
        token: token,
        merchantTransactionId: txnId,
      );

      return _buildResult(txnId, statusData, callbackUrl);
    } on EpsAuthException catch (e) {
      return EpsPaymentResult(
        status: EpsPaymentStatus.error,
        errorMessage: e.message,
      );
    } on EpsApiException catch (e) {
      return EpsPaymentResult(
        status: EpsPaymentStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      return EpsPaymentResult(
        status: EpsPaymentStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────

  static Future<String?> _pushFullScreen(
    BuildContext context,
    String redirectUrl,
  ) =>
      Navigator.of(context).push<String?>(
        MaterialPageRoute(
          builder: (_) => _EpsPaymentPage(redirectUrl: redirectUrl),
        ),
      );

  static Future<String?> _showBottomSheet(
    BuildContext context,
    String redirectUrl,
  ) =>
      showModalBottomSheet<String?>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: false,
        showDragHandle: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EpsPaymentSheet(redirectUrl: redirectUrl),
      );

  // ── Result helpers ─────────────────────────────────────────────────────

  static PaymentResult _resultFromCallback(String url) {
    if (url.startsWith('https://pixposbd.com/payment/success') ||
        url.startsWith(kEpsSuccessCallbackUrl)) {
      return const PaymentResult(
        status: PaymentStatus.success,
        message: 'Payment successful.',
      );
    }
    if (url.startsWith('https://pixposbd.com/payment/cancel') ||
        url.startsWith(kEpsCancelCallbackUrl)) {
      return const PaymentResult(
        status: PaymentStatus.cancelled,
        message: 'Payment cancelled by user.',
      );
    }
    return const PaymentResult(
      status: PaymentStatus.failed,
      message: 'Payment failed.',
    );
  }

  EpsPaymentResult _buildResult(
    String txnId,
    EpsTransactionStatus data,
    String callbackUrl,
  ) {
    final succeeded = data.status.toLowerCase() == 'success' ||
        callbackUrl.startsWith(kEpsSuccessCallbackUrl);

    return EpsPaymentResult(
      status: succeeded ? EpsPaymentStatus.success : EpsPaymentStatus.failed,
      merchantTransactionId: txnId,
      epsTransactionId: data.epsTransactionId.isEmpty
          ? null
          : data.epsTransactionId,
      errorMessage: data.errorMessage.isEmpty ? null : data.errorMessage,
      errorCode: data.errorCode.isEmpty ? null : data.errorCode,
      details: data,
    );
  }
}

// ── Private UI ───────────────────────────────────────────────────────────────

/// Full-screen Scaffold wrapping [EpsPaymentWebView].
class _EpsPaymentPage extends StatelessWidget {
  const _EpsPaymentPage({required this.redirectUrl});

  final String redirectUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: EpsPaymentWebView(
        redirectUrl: redirectUrl,
        onResult: (url) => Navigator.of(context).pop(url),
      ),
    );
  }
}

/// Modal bottom sheet wrapping [EpsPaymentWebView].
class _EpsPaymentSheet extends StatelessWidget {
  const _EpsPaymentSheet({required this.redirectUrl});

  final String redirectUrl;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: screenHeight * 0.92,
        child: Column(
          children: [
            _SheetHandle(onClose: () => Navigator.of(context).pop(null)),
            Expanded(
              child: EpsPaymentWebView(
                redirectUrl: redirectUrl,
                onResult: (url) => Navigator.of(context).pop(url),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drag handle and close button shown at the top of [_EpsPaymentSheet].
class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
