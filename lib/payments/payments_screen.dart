import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/order/place_order_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  Future<bool> checkoutCancelItems(int cartId) async {
    const String apiUrl = '$baseUrl/checkout-cancel';
    final Map<String, dynamic> payload = {'cart_id': cartId};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        // Assuming the server returns a simple true or false in the body
        return true;
      } else {
        // Handle the case when the server does not respond with a success code
        print('Request failed with status: ${response.statusCode}.');
        return false;
      }
    } on Exception catch (e) {
      // Handle any exceptions here
      print('Caught exception: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Call your function here
            String? cartId = cart.cartId;
            if (cartId != null) {
              int cartIdInt = int.parse(cartId);
              checkoutCancelItems(cartIdInt).then((success) {
                if (success) {
                  // If the checkout lock is successful, navigate to the PaymentsPage
                  Navigator.of(context).pop();
                } else {
                  // If the checkout lock is unsuccessful, you might want to show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to cancel checkout.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }).catchError((error) {
                // Handle any errors here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $error'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error: Cart Id Not Found'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
            // Then navigate back
          },
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.0,
                  colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                  tileMode: TileMode.mirror)
              .createShader(bounds),
          child: const Text(
            'Pronto Payments',
            style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        elevation: 4.0,
        backgroundColor: //Colors.deepPurpleAccent.shade100,
            Colors.white,
        foregroundColor: Colors.deepPurple,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: const Center(
        child: Text("Payment Gateway"),
      ),
      floatingActionButton: BottomAppBar(
        height: MediaQuery.of(context).size.height * 0.15,
        child: Container(
          padding: const EdgeInsets.only(left: 20),
          alignment: Alignment.center,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaceOrder(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              textStyle: Theme.of(context).textTheme.titleLarge,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.electric_bike_outlined),
                SizedBox(width: 10),
                Text('Pay'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
