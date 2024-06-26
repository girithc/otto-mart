import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/payments/verify.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/network/service.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PhonePeWebView extends StatefulWidget {
  final String url;
  final String merchantTransactionId;
  final String sign;

  const PhonePeWebView(
      {Key? key,
      required this.url,
      required this.sign,
      required this.merchantTransactionId})
      : super(key: key);

  @override
  State<PhonePeWebView> createState() => _PhonePeWebViewState();
}

class _PhonePeWebViewState extends State<PhonePeWebView> {
  late final WebViewController _controller;
  final storage = const FlutterSecureStorage();
  double _currentZoomLevel = 1.0; // Default zoom level
  late Timer _timer;
  Duration _remainingTime = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (navigation) {
            final host = Uri.parse(navigation.url).host;
            if (host.contains('youtube.com')) {
              processPayment().then((response) => {
                    if (response.isPaid)
                      {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentVerificationScreen(
                                merchantTransactionId:
                                    widget.merchantTransactionId),
                          ),
                        )
                      }
                    else
                      {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment Verification 400.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        ),
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentVerificationScreen(
                                merchantTransactionId:
                                    widget.merchantTransactionId),
                          ),
                        )
                      }
                  });

              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(widget.url));

    _controller = controller;

    _controller
      //..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setJavaScriptMode(JavaScriptMode.unrestricted).then((_) {
        _controller.runJavaScript("""
        (function() {
          var metaTag=document.createElement('meta');
          metaTag.name = "viewport";
          metaTag.content = "width=400";
          document.getElementsByTagName('head')[0].appendChild(metaTag);
        })();
      """);
      })
      ..addJavaScriptChannel(
        'SnackBar',
        onMessageReceived: (message) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message.message)));
        },
      );
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - Duration(seconds: 1);
        } else {
          _timer.cancel();
          // Time's up, you can add actions here if needed
        }
      });
    });
  }

  Future<bool> checkoutCancelItems(int cartId) async {
    _timer.cancel();
    final Map<String, dynamic> payload = {
      'cart_id': cartId,
      'sign': widget.sign,
      'merchantTransactionId': widget.merchantTransactionId,
      'lock_type': 'lock-stock-pay'
    };

    try {
      final networkService = NetworkService();
      final response = await networkService.postWithAuth('/checkout-cancel',
          additionalData: payload);

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

  Future<PayStockResponse> processPayment() async {
    String? cartId = await storage.read(key: 'cartId');
    int cartIdInt = int.parse(cartId!);
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('$baseUrl/checkout-payment'));
    final Map<String, dynamic> body = {
      "cart_id": cartIdInt,
      "cash": false,
      "sign": widget.sign,
      "merchant_transaction_id": widget.merchantTransactionId
    };
    request.headers.addAll(headers);

    try {
      final networkService = NetworkService();
      final response = await networkService.postWithAuth('/checkout-payment',
          additionalData: body);

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        final payStockResponse = PayStockResponse.fromJson(responseJson);

        // Use the PayStockResponse here as needed, for example:
        print(
            "Sign: ${payStockResponse.sign}, IsPaid: ${payStockResponse.isPaid}");

        return payStockResponse; // Return true if payment is successful
      } else {
        print(response.reasonPhrase);
        return PayStockResponse(sign: "", isPaid: false); // Payment failed
      }
    } catch (e) {
      print('Error: $e');
      return PayStockResponse(
          sign: "", isPaid: false); // Error occurred, treat as failed payment
    }
  }

  @override
  Widget build(BuildContext context) {
    //var cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () async {
            // Call your function here
            String? cartId = await storage.read(key: 'cartId');

            int cartIdInt = int.parse(cartId!);
            checkoutCancelItems(cartIdInt).then((success) {
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
            // Then navigate back
          },
        ),
        backgroundColor: Colors.deepPurpleAccent,
        title: InkWell(
          child: ShaderMask(
            shaderCallback: (bounds) => const RadialGradient(
              center: Alignment.centerRight,
              radius: 1.0,
              colors: [Colors.white, Colors.white70],
              tileMode: TileMode.mirror,
            ).createShader(bounds),
            child: const Text(
              'Pay',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        actions: [
          // Countdown Timer in AppBar's trailing part
          Center(
            child: Text(
              '${_remainingTime.inMinutes}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          SizedBox(width: 16), // Spacing after the timer
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class PayStockResponse {
  final String sign;
  final bool isPaid;

  PayStockResponse({required this.sign, required this.isPaid});

  factory PayStockResponse.fromJson(Map<String, dynamic> json) {
    return PayStockResponse(
      sign: json['sign'],
      isPaid: json['isPaid'],
    );
  }
}
