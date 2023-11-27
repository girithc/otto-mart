import 'dart:convert';
import 'package:pronto/payments/phonepe.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  late final WebViewController controller;
  var loadingPercentage = 0;
  String? _selectedPayment = 'PhonePe';

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            loadingPercentage = 0;
          });
        },
        onProgress: (progress) {
          setState(() {
            loadingPercentage = progress;
          });
        },
        onPageFinished: (url) {
          setState(() {
            loadingPercentage = 100;
          });
        },
      ))
      ..loadRequest(
        Uri.parse('https://flutter.dev'),
      );
  }

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

  Future<bool> processPayment(int cartId) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('$baseUrl/checkout-payment'));
    request.body = json.encode({"cart_id": cartId});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        print(await response.stream.bytesToString());
        return true; // Payment is successful
      } else {
        print(response.reasonPhrase);
        return false; // Payment failed
      }
    } catch (e) {
      print('Error: $e');
      return false; // Error occurred, treat as failed payment
    }
  }

  Future<String> initiatePhonePePayment(int cartId) async {
    var headers = {'Content-Type': 'application/json'};
    var request =
        http.Request('POST', Uri.parse('$baseUrl/phonepe-payment-init'));
    // Replace with actual parameters
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = json.decode(responseBody);

        // Correct path to extract the URL
        return decodedResponse['data']['instrumentResponse']['redirectInfo']
            ['url'];
      } else {
        // Handle non-200 responses
        var errorResponse = await response.stream.bytesToString();
        // Log the error response or handle it as per your application's requirement
        print('Error response: $errorResponse');
        return 'Error: Received status code ${response.statusCode}';
      }
    } catch (e) {
      // Handle exceptions
      print('Exception occurred: $e');
      return 'Exception: $e';
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
                  Navigator.of(context).pop();
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
            'Otto Pay',
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
      body: Column(
        children: [
          ListTile(
            title: const Text('PhonePe'),
            leading: Radio(
              value: 'PhonePe',
              groupValue: _selectedPayment,
              onChanged: (String? value) {
                setState(() {
                  _selectedPayment = value;
                });
              },
            ),
            onTap: () {
              setState(() {
                _selectedPayment = 'PhonePe';
              });
            },
          ),
          ListTile(
            title: const Text('Cash on Delivery'),
            leading: Radio(
              value: 'Cash',
              groupValue: _selectedPayment,
              onChanged: (String? value) {
                setState(() {
                  _selectedPayment = value;
                });
              },
            ),
            onTap: () {
              setState(() {
                _selectedPayment = 'Cash on Delivery';
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        child: Container(
          color: Colors.white,
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: () {
              String? cartId = cart.cartId;

              if (_selectedPayment == 'PhonePe' && cartId != null) {
                int cartIdInt = int.parse(cartId);
                initiatePhonePePayment(cartIdInt).then((url) {
                  if (url.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhonePeWebView(url: url),
                      ),
                    );
                  } else {}
                });
              } else if (_selectedPayment == 'Cash' && cartId != null) {
                int cartIdInt = int.parse(cartId);
                processPayment(cartIdInt).then((isPaid) {
                  if (isPaid) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaceOrder(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment failed'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $error'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                });
              }
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
