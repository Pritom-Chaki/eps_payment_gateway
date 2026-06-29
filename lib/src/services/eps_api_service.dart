import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/eps_config.dart';
import '../internal/eps_callback_urls.dart';
import '../models/eps_order.dart';
import '../models/eps_transaction_status.dart';
import 'eps_hash_service.dart';

/// Handles the EPS payment initialisation and transaction verification APIs.
class EpsApiService {
  const EpsApiService(this._config);

  final EpsConfig _config;

  // ── Public ────────────────────────────────────────────────────────────

  /// Calls `/v1/EPSEngine/InitializeEPS` and returns the redirect URL.
  ///
  /// Hash input: [merchantTransactionId].
  Future<String> initializePayment({
    required String token,
    required EpsOrder order,
    required String merchantTransactionId,
  }) async {
    final hash = computeEpsHash(_config.hashKey, merchantTransactionId);

    final body = jsonEncode(_buildPayload(order, merchantTransactionId));

    final response = await http.post(
      Uri.parse('${_config.baseUrl}/v1/EPSEngine/InitializeEPS'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'x-hash': hash,
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw EpsApiException(
        'InitializeEPS failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final redirectUrl = json['RedirectURL'] as String?;

    if (redirectUrl == null || redirectUrl.isEmpty) {
      throw EpsApiException(
        json['ErrorMessage'] as String? ?? 'No redirect URL returned by EPS.',
      );
    }

    return redirectUrl;
  }

  /// Calls `/v1/EPSEngine/CheckMerchantTransactionStatus` to verify a payment.
  ///
  /// Hash input: [merchantTransactionId].
  Future<EpsTransactionStatus> checkTransactionStatus({
    required String token,
    required String merchantTransactionId,
  }) async {
    final hash = computeEpsHash(_config.hashKey, merchantTransactionId);

    final response = await http.get(
      Uri.parse(
        '${_config.baseUrl}/v1/EPSEngine/CheckMerchantTransactionStatus'
        '?merchantTransactionId=$merchantTransactionId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'x-hash': hash,
      },
    );

    if (response.statusCode != 200) {
      throw EpsApiException(
        'CheckStatus failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return EpsTransactionStatus.fromJson(json);
  }

  // ── Internal ──────────────────────────────────────────────────────────

  Map<String, dynamic> _buildPayload(
    EpsOrder order,
    String merchantTransactionId,
  ) {
    return {
      'merchantId': _config.merchantId,
      'storeId': _config.storeId,
      'CustomerOrderId': order.orderId,
      'merchantTransactionId': merchantTransactionId,
      'transactionTypeId': order.transactionTypeId ?? _platformTransactionTypeId,
      'financialEntityId': 0,
      'transitionStatusId': 0,
      'totalAmount': order.amount,
      'ipAddress': '',
      'version': '1',
      'successUrl': kEpsSuccessCallbackUrl,
      'failUrl': kEpsFailCallbackUrl,
      'cancelUrl': kEpsCancelCallbackUrl,
      'customerName': order.customerName,
      'customerEmail': order.customerEmail,
      'customerAddress': order.customerAddress,
      'customerAddress2': order.customerAddress2,
      'customerCity': order.customerCity,
      'customerState': order.customerState,
      'customerPostcode': order.customerPostcode,
      'customerCountry': order.customerCountry,
      'customerPhone': order.customerPhone,
      'shipmentName': order.shipmentName ?? order.customerName,
      'shipmentAddress': order.shipmentAddress ?? order.customerAddress,
      'shipmentAddress2': order.shipmentAddress2 ?? '',
      'shipmentCity': order.shipmentCity ?? order.customerCity,
      'shipmentState': order.shipmentState ?? order.customerState,
      'shipmentPostcode': order.shipmentPostcode ?? order.customerPostcode,
      'shipmentCountry': order.shipmentCountry ?? order.customerCountry,
      'valueA': order.valueA ?? '',
      'valueB': order.valueB ?? '',
      'valueC': order.valueC ?? '',
      'valueD': order.valueD ?? '',
      'shippingMethod': order.shippingMethod ?? 'NO',
      'noOfItem': order.products.length.toString(),
      'productName': order.products.isNotEmpty ? order.products.first.name : '',
      'productProfile':
          order.products.isNotEmpty ? order.products.first.profile : '',
      'productCategory':
          order.products.isNotEmpty ? order.products.first.category : '',
      'ProductList': order.products.map((p) => p.toJson()).toList(),
    };
  }

  /// Returns 1 (Web), 2 (Android), or 3 (iOS) based on the current platform.
  int get _platformTransactionTypeId {
    if (kIsWeb) return 1;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 2;
      case TargetPlatform.iOS:
        return 3;
      default:
        return 1;
    }
  }
}

/// Thrown when an EPS API call fails.
class EpsApiException implements Exception {
  const EpsApiException(this.message);

  final String message;

  @override
  String toString() => 'EpsApiException: $message';
}
