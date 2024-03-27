import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pronto/cart/order/confirmed_order_screen.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/payments/Refund.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/network/service.dart';

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
      String? phone = await storage.read(key: "phone");
      final Map<String, dynamic> body = {
        "merchant_transaction_id": widget.merchantTransactionId,
        "cart_id": int.parse(cartId!),
        "phone": phone
      };

      final networkService = NetworkService();
      final response = await networkService.postWithAuth('/payment-verify',
          additionalData: body);

      print("Response For Verify: \n\n ${response.statusCode}");
      print(response.body);
      print("\n\n");

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
              builder: (context) => OrderConfirmed(newOrder: true),
            ),
          );
        } else {
          // Update UI for unsuccessful payment
          setState(() {
            displayText =
                'Payment Verification Failed: ${phonePeStatus.status}';
            displayIcon =
                const Icon(Icons.error_outline, color: Colors.red, size: 75);
          });
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    RefundsPage()), // Make sure CartScreen is defined and imported
          );
        }
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  RefundsPage()), // Make sure CartScreen is defined and imported
        );
      }
    } catch (e) {}
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
