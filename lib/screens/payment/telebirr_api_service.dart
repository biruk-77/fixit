import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:basic_utils/basic_utils.dart';
import 'config.dart'; // Make sure this path is correct for your project

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class TelebirrApiService {
  String? _token;

  TelebirrApiService({bool trustBadCertificate = false}) {
    if (trustBadCertificate) {
      debugPrint("WARNING: Enabling permissive HttpClientCertificate validation.");
      HttpOverrides.global = _MyHttpOverrides();
    }
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-APP-Key': AppConfig.appid, // Your Fabric App ID goes in the header
    };
    if (_token != null) {
      headers['Authorization'] = _token!;
    }
    return headers;
  }

  String _generateNonceStr() => 'nonce${DateTime.now().millisecondsSinceEpoch}';
  String _getTimestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  // --- THIS IS THE FINAL, CORRECT SIGNING FUNCTION ---
  String _signRequest(Map<String, dynamic> payload) {
    debugPrint("Attempting to sign payload with correct RSA logic...");
    try {
      final Map<String, String> paramsToSign = {};

      // Step 1: Gather all parameters from the payload for signing
      payload.forEach((key, value) {
        if (key != 'sign' &&
            key != 'biz_content' &&
            value != null &&
            value.toString().isNotEmpty) {
          paramsToSign[key] = value.toString();
        }
      });
      if (payload.containsKey('biz_content') && payload['biz_content'] is Map) {
        final bizContent = payload['biz_content'] as Map<String, dynamic>;
        bizContent.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            paramsToSign['biz_content_$key'] = value.toString();
          }
        });
      }

      // Step 2: Sort the keys alphabetically and build the string to sign
      final sortedKeys = paramsToSign.keys.toList()..sort();
      final stringToSign = sortedKeys
          .map((key) => '$key=${Uri.encodeComponent(paramsToSign[key]!)}')
          .join('&');

      debugPrint("--- String-to-Sign ---");
      debugPrint(stringToSign);
      debugPrint("----------------------");

      // Step 3: Perform the actual cryptographic RSA-SHA256 signing
      final privateKey = CryptoUtils.rsaPrivateKeyFromPem(AppConfig.privateKey);
      final signatureBytes = CryptoUtils.rsaSign(
          privateKey, Uint8List.fromList(utf8.encode(stringToSign)));

      // Step 4: Base64-encode the signature. This produces the final, correct sign string.
      final base64Signature = base64Encode(signatureBytes);
      debugPrint("Generated Base64 Signature: $base64Signature");
      return base64Signature;
    } catch (e, stackTrace) {
      debugPrint("!!! ERROR DURING SIGNING: $e\n$stackTrace");
      throw Exception("Failed to sign request: $e");
    }
  }

  String _encryptPin(String pin) {
    debugPrint("WARNING: Real PIN Encryption must be implemented!");
    return AppConfig.consumerPin; // Placeholder for testing
  }

  Future<Map<String, dynamic>> _postRequest(
      String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConfig.basicURL}$endpoint');
    final headers = _getHeaders();
    final requestBodyJson = jsonEncode(body);

    debugPrint('--- API Request to ${url.path} ---');
    debugPrint('Body: $requestBodyJson');

    try {
      final response = await http
          .post(url, headers: headers, body: requestBodyJson)
          .timeout(const Duration(seconds: 60));

      debugPrint('--- API Response from ${url.path} ---');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      Map<String, dynamic> responseBodyMap = {};
      if (response.body.isNotEmpty) responseBodyMap = jsonDecode(response.body);

      final responseCode = responseBodyMap['code']?.toString() ??
          responseBodyMap['errorCode']?.toString();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseCode != null &&
            responseCode != '0' &&
            responseCode != '200' &&
            responseCode != '20000') {
          throw Exception(
              'API Logic Error: Code $responseCode - ${responseBodyMap['msg'] ?? response.body}');
        }
        return responseBodyMap;
      } else {
        final errorMsg =
            responseBodyMap['errorMsg'] ?? jsonEncode(responseBodyMap);
        throw Exception(
            'API HTTP Error: ${response.statusCode} - (Code: ${responseCode ?? "N/A"}) $errorMsg');
      }
    } catch (e) {
      debugPrint('Error during API call to $endpoint: $e');
      rethrow;
    }
  }

  Future<String?> generateAppToken() async {
    final response = await _postRequest(
        '/payment/v1/token', {'appSecret': AppConfig.appSecret});
    final responseToken = response['token'] as String?;
    if (responseToken != null && responseToken.isNotEmpty) {
      _token = responseToken;
      debugPrint('Successfully obtained app token.');
      return _token;
    }
    throw Exception('Failed to get valid token from response.');
  }

  // --- THIS IS THE FINAL, CORRECT createOrder FUNCTION ---
  Future<String?> createOrder({
    required String totalAmount,
    required String merchOrderId,
    required String title,
    required String payeeIdentifier,
    required String notifyUrl,
    String transCurrency = 'ETB',
    String timeoutExpress = '120m',
    String tradeType = 'InApp',
    String businessType = 'P2PTransfer',
    String payeeIdentifierType = '01',
    String payeeType = '1000',
  }) async {
    if (_token == null) throw Exception('App token not available...');

    // bizContent is CORRECT (no 'appid' inside)
    final bizContent = {
      'trans_currency': transCurrency,
      'total_amount': totalAmount,
      'merch_order_id': merchOrderId,
      'merch_code': AppConfig.merchantCode,
      'timeout_express': timeoutExpress,
      'trade_type': tradeType,
      'notify_url': notifyUrl,
      'title': title,
      'business_type': businessType,
      'payee_identifier': payeeIdentifier,
      'payee_identifier_type': payeeIdentifierType,
      'payee_type': payeeType,
    };

    // payloadToSign is CORRECT
    // Your Merchant ID (`appid`) is correctly placed at the top level here.
    final payloadToSign = {
      'nonce_str': _generateNonceStr(),
      'method': 'payment.preorder',
      'timestamp': _getTimestamp(),
      'version': '1.0',
      'sign_type': 'SHA256WithRSA',
      'appid': AppConfig.merchantId,
      'biz_content': bizContent,
    };

    final payloadToSend = Map<String, dynamic>.from(payloadToSign)
      ..['sign'] = _signRequest(payloadToSign);

    final response =
        await _postRequest('/payment/v1/merchant/preOrder', payloadToSend);
    final prepayId = response['biz_content']?['prepay_id'] as String?;

    if (prepayId != null && prepayId.isNotEmpty) {
      debugPrint('Order created successfully. Prepay ID: $prepayId');
      return prepayId;
    } else {
      throw Exception(
          'Failed to get prepay_id from preOrder response. Server says: ${jsonEncode(response)}');
    }
  }

  Future<Map<String, dynamic>> payOrder(
      {required String prepayId,
      required String payerIdentifier,
      required String consumerPin}) async {
    if (_token == null) throw Exception('App token not available...');

    final bizContent = {
      'prepay_id': prepayId,
      'payer_identifier_type': '01',
      'payer_identifier': payerIdentifier,
      'payer_type': '1000',
      'security_credential': _encryptPin(consumerPin),
    };

    final payloadToSign = {
      'timestamp': _getTimestamp(), 'nonce_str': _generateNonceStr(),
      'method': 'payment.payorder',
      'sign_type': 'SHA256WithRSA', 'lang': 'en_US', 'version': '1.0',
      'app_code':
          AppConfig.merchantId, // Correctly uses 'app_code' for this request
      'biz_content': bizContent,
    };

    final payloadToSend = Map<String, dynamic>.from(payloadToSign)
      ..['sign'] = _signRequest(payloadToSign);

    final response =
        await _postRequest('/payment/v1/app/payOrder', payloadToSend);
    debugPrint("PayOrder response: ${jsonEncode(response)}");
    return response;
  }

  // --- The queryOrder method is correctly defined here ---
  Future<Map<String, dynamic>> queryOrder(
      {required String merchOrderId}) async {
    if (_token == null) throw Exception('App token not available...');

    final bizContent = {
      'merch_code': AppConfig.merchantCode,
      'merch_order_id': merchOrderId,
    };

    final payloadToSign = {
      'nonce_str': _generateNonceStr(),
      'method': 'payment.queryorder', // The correct method for querying
      'timestamp': _getTimestamp(),
      'version': '1.0',
      'sign_type': 'SHA256WithRSA',
      'appid': AppConfig.merchantId, // Use appid for signing
      'biz_content': bizContent,
    };

    final payloadToSend = Map<String, dynamic>.from(payloadToSign)
      ..['sign'] = _signRequest(payloadToSign);

    final response = await _postRequest(
        '/payment/v1/queryorder', payloadToSend); // Endpoint for query order
    debugPrint("QueryOrder response: ${jsonEncode(response)}");
    return response;
  }
}
