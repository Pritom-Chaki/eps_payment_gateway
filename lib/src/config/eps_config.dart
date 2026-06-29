/// EPS API environment selector.
enum EpsEnvironment {
  /// Sandbox / testing environment — `sandboxpgapi.eps.com.bd`.
  sandbox,

  /// Production / live environment — `pgapi.eps.com.bd`.
  live,
}

/// Merchant credentials and environment for the EPS payment gateway.
class EpsConfig {
  const EpsConfig({
    required this.merchantId,
    required this.storeId,
    required this.hashKey,
    required this.userName,
    required this.password,
    this.environment = EpsEnvironment.live,
  });

  final String merchantId;
  final String storeId;

  /// Secret key used to generate HMAC-SHA512 request signatures.
  final String hashKey;

  final String userName;
  final String password;
  final EpsEnvironment environment;

  String get baseUrl => environment == EpsEnvironment.sandbox
      ? 'https://sandboxpgapi.eps.com.bd'
      : 'https://pgapi.eps.com.bd';
}
