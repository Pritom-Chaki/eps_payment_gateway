import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../enums/payment_mode.dart';
import '../models/payment_result.dart';
import '../utils/exceptions.dart';

/// Calls the merchant's backend to initialise an EPS payment session.
///
/// Used only in [EPSMode.server] — the package never calls EPS directly.
class BackendService {
  /// POSTs [requestBody] to [initUrl].
  ///
  /// Expects a JSON response:
  /// ```json
  /// { "success": true, "redirect_url": "https://payment.eps.com.bd/..." }
  /// ```
  /// or
  /// ```json
  /// { "success": false, "message": "..." }
  /// ```
  Future<String> initialize({
    required Uri initUrl,
    required Map<String, dynamic> requestBody,
  }) async {
    try {
      final response = await http
          .post(
            initUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw BackendException(
          'Backend returned HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final success = json['success'] as bool? ?? false;

      if (!success) {
        throw const BackendException(
          'Backend returned success: false',
        );
      }

      final redirectUrl = json['redirect_url'] as String?;
      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw const BackendException(
          'Backend response is missing redirect_url.',
        );
      }

      return redirectUrl;
    } on TimeoutException {
      throw const BackendException('Backend request timed out after 30 seconds.');
    } on FormatException {
      throw const BackendException('Invalid JSON response from backend.');
    }
  }

  /// Called when the WebView lands on a callback URL to notify the
  /// backend about the outcome.  This is optional — the backend can
  /// also rely on EPS's own IPN/webhook.
  Future<void> notifyCallback({
    required Uri callbackUrl,
    required Map<String, dynamic> requestBody,
  }) async {
    try {
      await http
          .post(
            callbackUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Fire-and-forget — never throw from a notification call.
    }
  }

  /// Optionally verifies the payment with the backend.
  /// Returns a [PaymentResult] constructed from the backend response.
  Future<PaymentResult> verify({
    required Uri verifyUrl,
    required Map<String, dynamic> requestBody,
  }) async {
    try {
      final response = await http
          .post(
            verifyUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return PaymentResult(
          status: PaymentStatus.failed,
          message: 'Verification failed (HTTP ${response.statusCode})',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseVerification(json);
    } on TimeoutException {
      return const PaymentResult(
          status: PaymentStatus.failed,
          message: 'Verification request timed out.',
        );
      } on FormatException {
        return const PaymentResult(
          status: PaymentStatus.failed,
          message: 'Invalid JSON from verification endpoint.',
      );
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.failed,
        message: e.toString(),
      );
    }
  }

  PaymentResult _parseVerification(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;
    final transactionId = json['transaction_id'] as String?;
    final message = json['message'] as String?;

    if (success) {
      return PaymentResult(
        status: PaymentStatus.success,
        transactionId: transactionId,
        message: message ?? 'Payment successful.',
      );
    }

    return PaymentResult(
      status: PaymentStatus.failed,
      transactionId: transactionId,
      message: message ?? 'Payment verification failed.',
    );
  }
}
