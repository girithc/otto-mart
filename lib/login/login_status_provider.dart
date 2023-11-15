import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pronto/login/phone_api_client.dart';
import 'package:pronto/utils/constants.dart';

class LoginStatusProvider with ChangeNotifier {
  bool? isLoggedIn;
  String? customerId;

  final storage = const FlutterSecureStorage();

  LoginStatusProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    print("Attempt Login On Boot");
    customerId = await storage.read(key: 'customerId');
    String? phone = await storage.read(key: 'phone');

    if (phone == null) {
      isLoggedIn == false;
      await storage.deleteAll();

      notifyListeners();
      return;
    }
    final Map<String, dynamic> requestData = {
      "phone": int.parse(phone),
    };

    final http.Response response = await http.post(
      Uri.parse('$baseUrl/customer'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final Customer customer = Customer.fromJson(responseBody);
      await storage.write(key: 'customerId', value: customer.id.toString());
      await storage.write(key: 'phone', value: customer.phone.toString());
      await storage.write(key: 'cartId', value: customer.cartId.toString());
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
