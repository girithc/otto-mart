import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pronto/utils/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NetworkService {
  final String _baseUrl = baseUrl; // Base URL for the API
  String? phone; // User's phone number
  String? token; // Authentication token
  final storage = const FlutterSecureStorage();

  NetworkService() {
    _initialize();
  }

  // Asynchronously fetch phone and token from secure storage
  Future<void> _initialize() async {
    phone = await storage.read(key: 'customerId') ?? '';
    token = await storage.read(key: 'token') ?? '';
  }

  Future<http.Response> postWithAuth(String endpoint,
      {Map<String, dynamic>? additionalData}) async {
    // Ensure initialization is complete before proceeding
    await _initialize();

    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> body = {
      'phone_auth': phone,
      'token_auth': token,
    };

    // Add additional data if provided
    if (additionalData != null &&
        endpoint != '/login-customer' &&
        endpoint != '/customer' &&
        endpoint != '/verify-otp' &&
        endpoint != '/send-otp') {
      body.addAll(additionalData);
    }

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return response;
  }
}
