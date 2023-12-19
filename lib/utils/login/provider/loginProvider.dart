import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:master/main.dart';
import 'package:master/utils/constants.dart';
import 'package:master/utils/login/page/phone.dart';

class LoginProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> checkLogin(BuildContext context) async {
    String? packerId = await _storage.read(key: "packerId");
    String? storeId = await _storage.read(key: "storeId");
    // Call your API endpoint to check if packer exists
    if (packerId == null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const PhonePage(),
      ));
      return false;
    }
    String exists =
        await checkPackerExists(packerId); // Implement this function
    if (exists.length == 10) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const MyHomePage(title: 'Otto Master'),
      ));
      return true;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const PhonePage(),
    ));

    return false;
  }

  Future<String> checkPackerExists(String phoneNumber) async {
    try {
      var url = Uri.parse('$baseUrl/login-packer');
      final Map<String, dynamic> requestData = {
        "phone": int.parse(phoneNumber)
      };
      var response = await http.post(
        url,
        body: jsonEncode(requestData),
        headers: {"Content-Type": "application/json"},
      );
      // Send the POST request

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        // Assuming the API returns a JSON object with a field that indicates if the packer exists
        return data['phone']; // Replace 'exists' with the actual field name
      } else {
        // Handle non-200 responses
        print('Server error: ${response.statusCode}');
        return 'error';
      }
    } catch (e) {
      print('Error occurred: $e');
      return 'error';
    }
  }
}
