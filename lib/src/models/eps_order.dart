import 'eps_product.dart';

/// Payment order passed to [EpsPaymentGateway.pay].
class EpsOrder {
  const EpsOrder({
    required this.orderId,
    this.merchantTransactionId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.customerAddress,
    this.customerAddress2 = '',
    required this.customerCity,
    this.customerState = '',
    required this.customerPostcode,
    this.customerCountry = 'BD',
    this.shipmentName,
    this.shipmentAddress,
    this.shipmentAddress2,
    this.shipmentCity,
    this.shipmentState,
    this.shipmentPostcode,
    this.shipmentCountry,
    this.shippingMethod,
    this.valueA,
    this.valueB,
    this.valueC,
    this.valueD,
    this.transactionTypeId,
    this.products = const [],
  });

  /// Your internal order identifier. Must be unique per transaction.
  final String orderId;

  /// Unique EPS transaction identifier (≥ 10 digits).
  /// Auto-generated from current timestamp when omitted.
  final String? merchantTransactionId;

  final double amount;

  // ── Customer ──────────────────────────────────────────────────────────

  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String customerAddress;
  final String customerAddress2;
  final String customerCity;
  final String customerState;
  final String customerPostcode;
  final String customerCountry;

  // ── Shipment ──────────────────────────────────────────────────────────

  final String? shipmentName;
  final String? shipmentAddress;
  final String? shipmentAddress2;
  final String? shipmentCity;
  final String? shipmentState;
  final String? shipmentPostcode;
  final String? shipmentCountry;
  final String? shippingMethod;

  // ── Extra ─────────────────────────────────────────────────────────────

  final String? valueA;
  final String? valueB;
  final String? valueC;
  final String? valueD;

  /// Overrides auto-detected transaction type.
  /// EPS values: 1 = Web, 2 = Android, 3 = iOS.
  final int? transactionTypeId;

  final List<EpsProduct> products;
}
