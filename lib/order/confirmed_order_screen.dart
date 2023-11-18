import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pronto/utils/constants.dart';

class OrderConfirmed extends StatefulWidget {
  const OrderConfirmed({super.key});

  @override
  _OrderConfirmedState createState() => _OrderConfirmedState();
}

class _OrderConfirmedState extends State<OrderConfirmed> {
  late String _orderDetails;
  bool _isLoading = true;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    //fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    // Retrieve customerId and cartId from secure storage
    String? customerId = await _storage.read(key: 'customerId');
    String? cartId = await _storage.read(key: 'cartId');

    // Ensure both values are not null
    if (cartId == null || customerId == null) {
      throw Exception('Customer ID or Cart ID is missing');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/sales-order'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_id': int.parse(customerId),
        'cart_id': int.parse(cartId),
        // Add other necessary fields if any
      }),
    );

    print("CustomerId: $customerId, CartId: $cartId");

    if (response.statusCode == 200) {
      // Decode the JSON response
      Map<String, dynamic> responseData = json.decode(response.body);

      // Extract and print the 'payment_type' field
      String paymentType = responseData['payment_type'];
      print("Payment Type: $paymentType");

      if (responseData.isNotEmpty) {
        // Extracting the 'paid' field from the first object in the list
        String newCartId = responseData["new_cart_id"].toString();
        await _storage.write(key: 'cartId', value: newCartId);

        setState(() {
          _isLoading = false;
          _orderDetails = paymentType;
          print("Old Cart ID: $cartId");
          print("New Cart ID: $newCartId");
        });
      } else {
        throw Exception('Empty response data');
      }
    } else {
      throw Exception('Failed to load order details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            bottom: PreferredSize(
              preferredSize: const Size(0, 80),
              child: Container(),
            ),
            expandedHeight: MediaQuery.of(context).size.height * 0.4,
            title: ShaderMask(
              shaderCallback: (bounds) => const RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.0,
                      colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                      tileMode: TileMode.mirror)
                  .createShader(bounds),
              child: const Text(
                'Pronto',
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            backgroundColor: Colors.white,
            flexibleSpace: Stack(
              children: [
                Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.white,
                    )),
                Positioned(
                  bottom: -1,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(50),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverFixedExtentList(
            itemExtent: 150.0, // Updated height of each item
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                // Condition to build only 4 items

                return Container(
                  alignment: Alignment.center,
                  color: Colors.lightBlue[100 * (index + 1 % 9)],
                  child: Text('List Item $index'),
                ); // Return null for indices greater than 3
              },
              childCount: 4, // Specify the total number of children as 4
            ),
          ),
        ],
      ),
    );
  }
}
