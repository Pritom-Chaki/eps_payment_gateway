import 'eps_transaction_status.dart';

/// Outcome of a [EpsPaymentGateway.pay] call.
enum EpsPaymentStatus {
  /// Payment completed and verified successfully.
  success,

  /// Payment was attempted but failed or was rejected.
  failed,

  /// User cancelled the payment (closed the sheet or navigated back).
  cancelled,

  /// A network, API, or configuration error occurred.
  error,
}

/// Result returned to the caller after a payment attempt.
class EpsPaymentResult {
  const EpsPaymentResult({
    required this.status,
    this.merchantTransactionId,
    this.epsTransactionId,
    this.errorMessage,
    this.errorCode,
    this.details,
  });

  final EpsPaymentStatus status;

  /// Your merchant transaction ID (the one sent to EPS).
  final String? merchantTransactionId;

  /// EPS-assigned transaction ID (available after successful verification).
  final String? epsTransactionId;

  final String? errorMessage;
  final String? errorCode;

  /// Full transaction record from the EPS verify endpoint.
  final EpsTransactionStatus? details;

  bool get isSuccess => status == EpsPaymentStatus.success;
  bool get isFailed => status == EpsPaymentStatus.failed;
  bool get isCancelled => status == EpsPaymentStatus.cancelled;
  bool get isError => status == EpsPaymentStatus.error;
}
