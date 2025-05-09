import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pronto/login/phone_api_client.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/network/service.dart';

class LoginStatusProvider with ChangeNotifier {
  bool? isLoggedIn;
  String? customerId;

  final storage = const FlutterSecureStorage();

  LoginStatusProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    print("Attempt Login On Boot Inside");
    customerId = await storage.read(key: 'customerId');
    String? phone = await storage.read(key: 'phone');
    String? fcmToken = await storage.read(key: 'fcm');
    print("Phone: $phone");

    if (phone == null) {
      isLoggedIn == false;
      await storage.deleteAll();

      notifyListeners();
      return;
    }
    final Map<String, dynamic> requestData = {
      "phone": phone,
      "fcm": fcmToken,
    };

    final networkService = NetworkService();

    final response = await networkService.postWithAuth('/customer',
        additionalData: requestData);

    print("Reponse for login: ${response.statusCode} ${response.body} ");
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final CustomerAutoLogin customer =
          CustomerAutoLogin.fromJson(responseBody);
      await storage.write(key: 'customerId', value: customer.id.toString());
      await storage.write(key: 'phone', value: customer.phone);
      await storage.write(key: 'name', value: customer.name);
      await storage.write(key: 'authToken', value: customer.token);
      isLoggedIn = true;
      notifyListeners();
    } else {
      await storage.deleteAll();
      throw Exception('Failed to login Customer');
    }
  }

  void updateLoginStatus(bool status, String? newCustomerId) {
    isLoggedIn = status;
    customerId = newCustomerId;
    notifyListeners();
  }
}

class CustomerAutoLogin {
  final int id;
  final String name;
  final String phone;
  final String address;
  final String token;

  CustomerAutoLogin({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.token,
  });

  factory CustomerAutoLogin.fromJson(Map<String, dynamic> json) {
    return CustomerAutoLogin(
      id: json['id'] as int,
      name: json['name'] as String? ??
          '', // Provide a default empty string if null
      phone: json['phone'] as String,
      address: json['address'] as String? ??
          '', // Provide a default empty string if null
      token: json['token'] as String? ??
          '', // Provide a default empty string if null
    );
  }
}
