import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pronto/cart/order/confirmed_order_screen.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/utils/constants.dart';

class PaymentVerificationScreen extends StatefulWidget {
  const PaymentVerificationScreen({super.key});

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
      final response = await http.post(
        Uri.parse('$baseUrl/payment-verify'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          // Your request body here
        }),
      );

      if (response.statusCode == 200) {
        // Delay for 5 seconds before updating the UI
        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          displayText = 'Payment Verified';
          displayIcon = const Icon(Icons.check_circle_outline,
              color: Colors.green, size: 75);
        });

        // Additional 2-second delay before navigating to the homepage
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MyHomePage(
                      title: "Otto Mart",
                    )));
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
