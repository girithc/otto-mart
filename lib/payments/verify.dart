import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pronto/cart/order/confirmed_order_screen.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/utils/constants.dart';

class PaymentVerificationScreen extends StatefulWidget {
  const PaymentVerificationScreen(
      {super.key, required this.merchantTransactionId});
  final String merchantTransactionId;

  @override
  _PaymentVerificationScreenState createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  String displayText = 'Verifying Payment';
  Icon displayIcon = const Icon(
    Icons.hourglass_empty,
    size: 55,
  );

  @override
  void initState() {
    super.initState();
    verifyPayment();
  }

  Future<void> verifyPayment() async {
    try {
      const storage = FlutterSecureStorage();

      // Retrieve cartId and customerId from secure storage
      String? cartId = await storage.read(key: "cartId");
      String? customerId = await storage.read(key: "customerId");

      final response = await http.post(
        Uri.parse('$baseUrl/payment-verify'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "merchant_transaction_id": widget.merchantTransactionId,
          "cart_id": int.parse(cartId!),
          "phone": customerId
        }),
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        // Decode the JSON response
        final responseData = jsonDecode(response.body);
        final phonePeStatus = PhonePeCheckStatus.fromJson(responseData);

        // Use the data from the response
        if (phonePeStatus.done) {
          // Update UI for successful payment
          setState(() {
            displayText = 'Payment Verified: ₹${phonePeStatus.amount}';
            displayIcon = const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 75);
          });

          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => OrderConfirmed(newOrder: true)));
        } else {
          // Update UI for unsuccessful payment
          setState(() {
            displayText =
                'Payment Verification Failed: ${phonePeStatus.status}';
            displayIcon =
                const Icon(Icons.error_outline, color: Colors.red, size: 75);
          });
        }
      } else {
        // Handle error or unsuccessful verification
      }
    } catch (e) {
      // Handle exception
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Verification')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            displayIcon,
            const SizedBox(height: 20),
            Text(
              displayText,
              style: const TextStyle(fontSize: 25),
            ),
          ],
        ),
      ),
    );
  }
}

class PhonePeCheckStatus {
  final String status;
  final bool done;
  final int amount;
  final String payment_method;

  PhonePeCheckStatus(
      {required this.status,
      required this.done,
      required this.amount,
      required this.payment_method});

  factory PhonePeCheckStatus.fromJson(Map<String, dynamic> json) {
    return PhonePeCheckStatus(
        status: json['status'],
        done: json['done'],
        amount: json['amount'],
        payment_method: json['payment_method']);
  }
}
