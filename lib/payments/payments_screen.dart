import 'dart:convert';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/cart/order/confirmed_order_screen.dart';
import 'package:pronto/payments/phonepe.dart';
import 'package:pronto/utils/network/service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/order/place_order_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage(
      {super.key, required this.sign, required this.merchantTransactionID});
  final String sign;
  final String merchantTransactionID;
  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  late final WebViewController controller;
  var loadingPercentage = 0;
  final String _selectedPayment = 'PhonePe';

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
      'sign': widget.sign,
      'merchantTransactionId': widget.merchantTransactionID,
      'lock_type': 'lock-stock'
    };

    try {
      final networkService = NetworkService();
      final response = await networkService.postWithAuth('/checkout-cancel',
          additionalData: payload);

      /*final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(payload),
      );
      */

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
    final Map<String, dynamic> body = {
      "cart_id": cartId,
      "cash": cash,
      "sign": widget.sign,
      "merchant_transaction_id": widget.merchantTransactionID
    };

    try {
      //var response = await http.post(url, headers: headers, body: body);

      final networkService = NetworkService();
      final response = await networkService.postWithAuth('/checkout-payment',
          additionalData: body);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print(response.body);
        bool isPaid =
            responseData['isPaid'] ?? false; // Extracting the isPaid value
        return isPaid; // Return the extracted boolean
      } else {
        print('Failed: ${response.reasonPhrase} ${response.body}');
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
    final Map<String, dynamic> body = {
      "cart_id": cartId,
      "sign": widget.sign,
      "merchantTransactionId": widget.merchantTransactionID
    };
    request.headers.addAll(headers);

    try {
      final networkService = NetworkService();
      final response = await networkService
          .postWithAuth('/phonepe-payment-init', additionalData: body);
      //http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        //var responseBody = await response.stream.bytesToString();
        var decodedResponse = json.decode(response.body);

        print(decodedResponse);
        String url = decodedResponse['data']['instrumentResponse']
            ['redirectInfo']['url'];
        String message = decodedResponse['message'];
        bool isSuccess = decodedResponse['success'];
        String sign = decodedResponse['sign'];
        String merchantTransactionId = decodedResponse['merchantTransactionId'];

        if (isSuccess) {
          return PaymentResult(
              url: url,
              isSuccess: isSuccess,
              sign: sign,
              merchantTransactionId: merchantTransactionId);
        } else {
          return PaymentResult(
              url: message,
              isSuccess: isSuccess,
              sign: sign,
              merchantTransactionId: '');
        }
      } else {
        //var errorResponse = await response.stream.bytesToString();
        print(
            'Request failed with status: ${response.statusCode}. ${response.body}');
        //throw Exception('Failed to cancel checkout items');
        //print('Error response: $errorResponse');
        return PaymentResult(
            url: 'Payment Error',
            isSuccess: false,
            sign: '',
            merchantTransactionId: '');
      }
    } catch (e) {
      print('Exception occurred: $e');
      return PaymentResult(
          url: 'Exception: $e',
          isSuccess: false,
          sign: '',
          merchantTransactionId: '');
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
              print('CartID: $cartIdInt');
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
          const SizedBox(
            height: 50,
          ),
          InkWell(
            onTap: () {
              String? cartId = cart.cartId;
              int cartIdInt = int.parse(cartId!);
              initiatePhonePePayment(cartIdInt).then((response) {
                if (response.isSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhonePeWebView(
                        url: response.url,
                        sign: response.sign,
                        merchantTransactionId: response.merchantTransactionId,
                      ),
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
            },
            child: Container(
              margin:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 107, 53, 255),
                    Colors.deepPurpleAccent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child:
                            Image.asset('assets/icon/phonepe.png', height: 50),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 2),
                          const Text(
                            'PhonePe',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          _paymentMethodRow(
                              Icons.currency_rupee_outlined, 'UPI'),
                          _paymentMethodRow(
                              Icons.credit_card_outlined, 'Credit Card'),
                          _paymentMethodRow(
                              Icons.credit_card_outlined, 'Debit Card'),
                          _paymentMethodRow(
                              Icons.account_balance_outlined, 'Net Banking'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              String? cartId = cart.cartId;
              int cartIdInt = int.parse(cartId!);
              processPayment(cartIdInt, true).then((isPaid) {
                if (isPaid) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderConfirmed(newOrder: true),
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
            },
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white, // Set the background color to white
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey
                        .withOpacity(0.5), // Shadow color with some opacity
                    spreadRadius: 0, // Shadow spread radius
                    blurRadius: 6, // Shadow blur radius
                    offset: const Offset(0, 3), // Shadow position
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.money_outlined),
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 2),
                          Text(
                            'Cash On Delivery',
                            style: TextStyle(
                                color: Colors.black87,
                                fontSize: 22,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create a row with an icon and text
  Widget _paymentMethodRow(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentResult {
  final String url;
  final bool isSuccess;
  final String sign;
  final String merchantTransactionId;

  PaymentResult(
      {required this.url,
      required this.isSuccess,
      required this.sign,
      required this.merchantTransactionId});
}
