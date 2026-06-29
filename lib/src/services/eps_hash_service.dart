import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Computes the HMAC-SHA512 `x-hash` header value required by every EPS endpoint.
///
/// Algorithm (from EPS API docs):
/// 1. Encode [hashKey] as UTF-8 bytes.
/// 2. Create an HMAC-SHA512 instance using those bytes as the key.
/// 3. Compute the digest over UTF-8 encoded [input].
/// 4. Return the Base64 string of the digest bytes.
String computeEpsHash(String hashKey, String input) {
  final keyBytes = utf8.encode(hashKey);
  final hmac = Hmac(sha512, keyBytes);
  final digest = hmac.convert(utf8.encode(input));
  return base64.encode(digest.bytes);
}
