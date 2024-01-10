import 'dart:convert';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/payments/phonepe.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/order/place_order_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key, required this.sign});
  final String sign;
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

  Future<bool> checkoutCancelItems(int cartId, String sign) async {
    const String apiUrl = '$baseUrl/checkout-cancel';
    final Map<String, dynamic> payload = {
      'cart_id': cartId,
      'sign': sign,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        // Parse the JSON response into a LockStockResponse object
        final jsonResponse = json.decode(response.body);
        return true;
      } else {
        // Handle the case when the server does not respond with a success code
        print('Request failed with status: ${response.body}.');
        throw Exception('Failed to cancel checkout items');
      }
    } on Exception catch (e) {
      // Handle any exceptions here
      print('Caught exception: $e');
      return false; // Re-throw the caught exception
    }
  }

  Future<bool> processPayment(int cartId, bool cash) async {
    var headers = {'Content-Type': 'application/json'};
    var url = Uri.parse('$baseUrl/checkout-payment');
    var body =
        json.encode({"cart_id": cartId, "cash": cash, "sign": widget.sign});

    try {
      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print(response.body);
        bool isPaid =
            responseData['isPaid'] ?? false; // Extracting the isPaid value
        return isPaid; // Return the extracted boolean
      } else {
        print('Failed: ${response.reasonPhrase}');
        return false; // Payment failed
      }
    } catch (e) {
      print('Error during payment processing: $e');
      return false; // Error occurred, treat as failed payment
    }
  }

  Future<PaymentResult> initiatePhonePePayment(int cartId) async {
    var headers = {'Content-Type': 'application/json'};
    var request =
        http.Request('POST', Uri.parse('$baseUrl/phonepe-payment-init'));
    request.body = json.encode({"cart_id": cartId, "sign": widget.sign});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = json.decode(responseBody);

        // Assuming the URL is correctly found in the response
        print(responseBody);
        String url = decodedResponse['data']['instrumentResponse']
            ['redirectInfo']['url'];
        String message = decodedResponse['message'];
        bool isSuccess = decodedResponse['success'];

        if (isSuccess) {
          return PaymentResult(
              url: url, isSuccess: isSuccess, merchantTransactionId: '');
        } else {
          return PaymentResult(
              url: message, isSuccess: isSuccess, merchantTransactionId: '');
        }
      } else {
        var errorResponse = await response.stream.bytesToString();
        print('Error response: $errorResponse');
        return PaymentResult(
            url: 'Payment Error', isSuccess: false, merchantTransactionId: '');
      }
    } catch (e) {
      print('Exception occurred: $e');
      return PaymentResult(
          url: 'Exception: $e', isSuccess: false, merchantTransactionId: '');
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
              checkoutCancelItems(cartIdInt, widget.sign).then((success) {
                if (success) {
                  // If the checkout lock is successful, navigate to the PaymentsPage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyCart(),
                    ),
                  );
                } else {
                  // If the checkout lock is unsuccessful, you might want to show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to cancel checkout.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyCart(),
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
                initiatePhonePePayment(cartIdInt).then((response) {
                  if (response.isSuccess) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhonePeWebView(url: response.url),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          response.url,
                          style: const TextStyle(color: Colors.black),
                        ),
                        backgroundColor: Colors.amberAccent,
                      ),
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyCart(),
                      ),
                    );
                  }
                });
              } else if (_selectedPayment == 'Cash' && cartId != null) {
                int cartIdInt = int.parse(cartId);
                processPayment(cartIdInt, true).then((isPaid) {
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
                        content: Text(
                          'Timeout: Payment Failed',
                          style: TextStyle(color: Colors.black),
                        ),
                        backgroundColor: Colors.amberAccent,
                      ),
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyCart(),
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

class PaymentResult {
  final String url;
  final bool isSuccess;
  final String merchantTransactionId;

  PaymentResult(
      {required this.url,
      required this.isSuccess,
      required this.merchantTransactionId});
}
