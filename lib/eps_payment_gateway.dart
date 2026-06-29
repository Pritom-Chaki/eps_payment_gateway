/// Flutter package for EPS (Easy Payment System) payment gateway integration.
///
/// Supports sandbox and live environments. Handles HMAC-SHA512 request signing,
/// JWT authentication, WebView payment flow, and transaction verification
/// automatically — callers only interact with [EpsPaymentGateway.pay].
library;

export 'src/config/eps_config.dart';
export 'src/config/eps_display_mode.dart';
export 'src/models/eps_order.dart';
export 'src/models/eps_payment_result.dart';
export 'src/models/eps_product.dart';
export 'src/models/eps_transaction_status.dart';
export 'src/eps_payment_gateway_impl.dart';
