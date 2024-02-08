import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:packer/utils/constants.dart';
import 'package:packer/utils/network/service.dart';

class LoginProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> checkLogin() async {
    String? packerId = await _storage.read(key: "packerId");
    String? storeId = await _storage.read(key: "storeId");
    // Call your API endpoint to check if packer exists
    if (packerId == null) {
      return false;
    }
    String exists =
        await checkPackerExists(packerId); // Implement this function
    if (exists.length == 10) {
      return true;
    }

    return false;
  }

  Future<String> checkPackerExists(String phoneNumber) async {
    try {
      final Map<String, dynamic> requestData = {"phone": phoneNumber};

      final networkService = NetworkService();
      var response = await networkService.postWithAuth('/login-packer',
          additionalData: requestData);
      // Send the POST request

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        // Assuming the API returns a JSON object with a field that indicates if the packer exists
        print("Login Successful ${data['phone']}");

        return data['phone']; // Replace 'exists' with the actual field name
      } else {
        // Handle non-200 responses
        print('Server error: ${response.statusCode}');
        print(response.body);
        return 'error';
      }
    } catch (e) {
      print('Error occurred: $e');
      return 'error';
    }
  }
}

class Packer {
  final int id;
  final String name;
  final String phone;
  final String address;
  final String createdAt;

  Packer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.createdAt,
  });

  factory Packer.fromJson(Map<String, dynamic> json) {
    return Packer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      createdAt: json['created_at'],
    );
  }
}
