import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/deprecated/cart.dart';
import 'package:pronto/order/place_order_screen.dart';
import 'package:pronto/setting/setting_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PhonePeWebView extends StatefulWidget {
  final String url;

  const PhonePeWebView({Key? key, required this.url}) : super(key: key);

  @override
  State<PhonePeWebView> createState() => _PhonePeWebViewState();
}

class _PhonePeWebViewState extends State<PhonePeWebView> {
  late final WebViewController _controller;
  final storage = const FlutterSecureStorage();

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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Blocking navigation to $host',
                  ),
                ),
              );
              processPayment().then((isPaid) => {
                    if (isPaid)
                      {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlaceOrder(),
                          ),
                        )
                      }
                    else
                      {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingScreen(),
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
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SnackBar',
        onMessageReceived: (message) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message.message)));
        },
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

  Future<bool> processPayment() async {
    String? cartId = await storage.read(key: 'cartId');
    int cartIdInt = int.parse(cartId!);
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('$baseUrl/checkout-payment'));
    request.body = json.encode({"cart_id": cartIdInt});
    request.headers.addAll(headers);

    try {
      final http.Response response = await http.post(
          Uri.parse('$baseUrl/checkout-payment'),
          body: request.body,
          headers: headers);

      if (response.statusCode == 200) {
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

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            // Call your function here
            String? cartId = cart.cartId;
            int cartIdInt = int.parse(cartId!);
            checkoutCancelItems(cartIdInt).then((success) {
              if (success) {
                // If the checkout lock is successful, navigate to the PaymentsPage
                Navigator.push(
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
            // Then navigate back
          },
        ),
        backgroundColor: Colors.deepPurpleAccent,
        title: InkWell(
          child: ShaderMask(
            shaderCallback: (bounds) => const RadialGradient(
              center: Alignment.topLeft,
              radius: 1.0,
              colors: [Colors.white, Colors.white70],
              tileMode: TileMode.mirror,
            ).createShader(bounds),
            child: const Text(
              'Otto Mart Pay',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
