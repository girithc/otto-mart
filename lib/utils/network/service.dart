import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pronto/utils/constants.dart';

class NetworkService {
  final String _baseUrl = baseUrl; // Base URL for the API
  final String phone; // User's phone number
  final String token; // Authentication token

  NetworkService({required this.phone, required this.token});

  Future<http.Response> postWithAuth(String endpoint,
      {Map<String, dynamic>? additionalData}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> body = {
      'phone_auth': phone,
      'token_auth': token,
    };

    // Add additional data if provided
    if (additionalData != null) {
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
