import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/payment_event.dart';

class ApiService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  
  // TODO: Configure your real endpoint and secret here
  static const String _baseUrl = 'https://api.example.com/v1/events';
  static const String _sharedSecret = 'YOUR_SECURE_SHARED_SECRET_KEY_CHANGE_ME';

  ApiService() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['User-Agent'] = 'AutoVerify/1.0';
  }

  /// Uploads a list of events to the backend.
  /// Returns true if successful, false otherwise.
  Future<bool> uploadEvents(List<PaymentEvent> events) async {
    if (events.isEmpty) return true;

    try {
      final payload = jsonEncode(events.map((e) => e.toJson()).toList());
      final signature = _generateHmac(payload);

      _logger.i('Uploading ${events.length} events. Signature: $signature');

      final response = await _dio.post(
        _baseUrl,
        data: payload,
        options: Options(
          headers: {
            'X-PAY-SIGN': signature,
            'X-DEVICE-ID': 'device-id-placeholder', // TODO: Add real device ID
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('Upload successful: ${response.data}');
        return true;
      } else {
        _logger.w('Upload failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Error uploading events: $e');
      return false;
    }
  }

  String _generateHmac(String payload) {
    final key = utf8.encode(_sharedSecret);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }
}
