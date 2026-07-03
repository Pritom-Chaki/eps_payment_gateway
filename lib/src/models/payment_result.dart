/// Outcome status of a payment attempt.
enum PaymentStatus {
  /// Payment completed successfully.
  success,

  /// Payment was attempted but failed.
  failed,

  /// User cancelled the payment.
  cancelled,
}

/// Result returned by [EpsPaymentGateway.startPayment].
class PaymentResult {
  const PaymentResult({
    required this.status,
    this.transactionId,
    this.message,
  });

  /// Payment outcome: [PaymentStatus.success], [PaymentStatus.failed],
  /// or [PaymentStatus.cancelled].
  final PaymentStatus status;

  /// Transaction identifier returned by the backend (optional).
  final String? transactionId;

  /// Human-readable message describing the result.
  final String? message;
}
