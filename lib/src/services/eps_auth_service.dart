import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/eps_config.dart';
import 'eps_hash_service.dart';

/// Authenticates with the EPS Auth API and returns a JWT Bearer token.
class EpsAuthService {
  const EpsAuthService(this._config);

  final EpsConfig _config;

  // ── Public ────────────────────────────────────────────────────────────

  /// Calls `/v1/Auth/GetToken` and returns the raw JWT string.
  ///
  /// Hash input: [EpsConfig.userName].
  Future<String> getToken() async {
    final hash = computeEpsHash(_config.hashKey, _config.userName);

    final baseUrl = kIsWeb && _config.webAuthEndpoint != null
        ? _config.webAuthEndpoint!
        : _config.baseUrl;

    final response = await http.post(
      Uri.parse('$baseUrl/v1/Auth/GetToken'),
      headers: {
        'Content-Type': 'application/json',
        'x-hash': hash,
      },
      body: jsonEncode({
        'userName': _config.userName,
        'password': _config.password,
      }),
    );

    if (response.statusCode != 200) {
      throw EpsAuthException(
        'GetToken failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final token = json['token'] as String?;

    if (token == null || token.isEmpty) {
      throw EpsAuthException(
        json['errorMessage'] as String? ?? 'Token not returned by EPS.',
      );
    }

    return token;
  }
}

/// Thrown when EPS token acquisition fails.
class EpsAuthException implements Exception {
  const EpsAuthException(this.message);

  final String message;

  @override
  String toString() => 'EpsAuthException: $message';
}
