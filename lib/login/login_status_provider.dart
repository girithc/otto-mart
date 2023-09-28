import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginStatusProvider with ChangeNotifier {
  bool? isLoggedIn;
  String? customerId;

  final storage = const FlutterSecureStorage();

  LoginStatusProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    customerId = await storage.read(key: 'customerId');
    isLoggedIn = customerId != null;
    notifyListeners();
  }

  void updateLoginStatus(bool status, String? newCustomerId) {
    isLoggedIn = status;
    customerId = newCustomerId;
    notifyListeners();
  }
}
