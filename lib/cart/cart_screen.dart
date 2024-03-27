// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pronto/cart/address/screen/saved_address.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/payments/payments_screen.dart';
import 'package:pronto/payments/phonepe.dart';
import 'package:pronto/utils/network/service.dart';
import 'package:provider/provider.dart';

class MyCart extends StatefulWidget {
  const MyCart({super.key});
  static const String routeName = '/myCart';

  @override
  State<MyCart> createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  String? streetAddress;
  String? cartId;
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  bool storeOpen = true;
  String storeOpenTime = '';

  @override
  void initState() {
    fetchCartId();
    super.initState();
    getStoreAddress();
  }

  Future<void> fetchCartId() async {
    //await Future.delayed(const Duration(seconds: 3)); // Introduce a 3-second delay

    cartId = await storage.read(key: 'cartId');
  }

  Future<LockStockResponse> checkoutLockItems(int cartId) async {
    //const String apiUrl = '$baseUrl/checkout-lock-items';
    final Map<String, dynamic> body = {'cart_id': cartId};
    final networkService = NetworkService();

    try {
      final response = await networkService.postWithAuth('/checkout-lock-items',
          additionalData: body);
      print("Checkout Lock Response: ${response.body} ${response.statusCode}");

      if (response.statusCode == 200) {
        // Parse the JSON response into a LockStockResponse object
        final jsonResponse = json.decode(response.body);
        return LockStockResponse.fromJson(jsonResponse);
      } else {
        // Handle the case when the server does not respond with a success code
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to cancel checkout items');
      }
    } on Exception catch (e) {
      // Handle any exceptions here
      print('Caught exception: $e');
      throw Exception(e); // Re-throw the caught exception
    }
  }

  Future<void> getStoreAddress() async {
    print("Entered Get Store Address");
    final storeId = await storage.read(key: 'storeId');
    final networkService = NetworkService();
    Map<String, dynamic> body = {
      "store_id": int.parse(storeId!),
    };
    final response = await networkService.postWithAuth('/store-address',
        additionalData: body);

    print("Response Store Address ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        streetAddress = data['address'];
        storeOpen = data['store_open'];
        if (!storeOpen) {
          DateTime parsedStoreOpenTime = DateTime.parse(data['opening_time']);

          // Add 5 hours and 30 minutes to the parsed time
          DateTime adjustedStoreOpenTime =
              parsedStoreOpenTime.add(Duration(hours: 5, minutes: 30));

          // Format the adjusted time part into a verbal format like "9:00 AM"
          storeOpenTime = DateFormat('h:mm a').format(adjustedStoreOpenTime);
        }
      });
    } else {}
  }

  Future<PaymentResult> initiatePhonePePayment() async {
    cartId = await storage.read(key: 'cartId');
    final Map<String, dynamic> body = {
      "cart_id": int.parse(cartId!),
    };

    try {
      final networkService = NetworkService();
      final response = await networkService
          .postWithAuth('/phonepe-payment-init', additionalData: body);
      //http.StreamedResponse response = await request.send();

      print("Response: ${response.body} ${response.statusCode}");

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
    bool hasDeliveryAddress = !cart.deliveryAddress.isEmpty();

    return FutureBuilder(
      future: fetchCartId(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        // Check if the future is complete
        if (snapshot.connectionState == ConnectionState.done) {
          // Future is complete, you can use the fetched cartId here
          return Scaffold(
            appBar: AppBar(
              title: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyHomePage(
                        title: 'Otto Mart',
                      ),
                    ),
                  );
                },
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyHomePage(
                            title: 'Otto Mart',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Add More Items +',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    )),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  // Navigate to the homepage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyHomePage(
                        title: 'Otto Mart',
                      ),
                    ),
                  );
                },
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              shadowColor: Colors.white,
              surfaceTintColor: Colors.white,
              centerTitle: true,
            ),
            body: Container(
              color: const Color.fromARGB(255, 253, 248, 255),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: CartList(
                        streetAddress: streetAddress ??
                            "", // Fallback to an empty string if streetAddress is null
                        isLoading: isLoading,
                      ),
                    ),
                  )

                  //const Divider(height: 4, color: Colors.black),
                ],
              ),
            ),
            bottomNavigationBar: !hasDeliveryAddress
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 253, 248, 255),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [], // Add border
                    ),
                    padding: EdgeInsets.zero,
                    margin: const EdgeInsets.only(top: 20),
                    height: MediaQuery.of(context).size.height * 0.15,
                    child: Column(
                        // Align children at the start
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                                left: 12, right: 12, bottom: 20, top: 0),
                            height: MediaQuery.of(context).size.height *
                                (0.18 - 0.065),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SavedAddressScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                      fontWeight: FontWeight
                                          .bold, // Making the font bold
                                    ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      20.0), // Slightly more rounded
                                ),
                                elevation: 5, // Adding some shadow for depth
                                side: BorderSide(
                                    color: Colors.pink[200]!,
                                    width: 2), // Border for a more defined look
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.electric_bike_outlined),
                                  SizedBox(width: 10),
                                  Text('Enter Delivery Address'),
                                ],
                              ),
                            ),
                          ),
                        ]))
                : Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 253, 248, 255),
                      borderRadius: BorderRadius.circular(0),
                      boxShadow: const [], // Add border
                    ),
                    padding: EdgeInsets.zero,
                    margin: EdgeInsets.zero,
                    height: MediaQuery.of(context).size.height * 0.15,
                    child: !(cart.isEmpty())
                        ? Column(
                            // Align children at the start
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                  padding: const EdgeInsets.only(
                                      left: 20, right: 20, bottom: 10, top: 2),
                                  height: MediaQuery.of(context).size.height *
                                      (0.18 - 0.065),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      String? cartId =
                                          await storage.read(key: 'cartId');
                                      if (storeOpen) {
                                        if (cartId != null) {
                                          int cartIdInt = int.parse(cartId);
                                          print("CartID INT: $cartIdInt");

                                          checkoutLockItems(cartIdInt)
                                              .then((success) {
                                            if (success.lock) {
                                              // If the checkout lock is successful, navigate to the PaymentsPage
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PaymentsPage(
                                                    sign: success.sign,
                                                    merchantTransactionID: success
                                                        .merchantTransactionID,
                                                    amount: cart.totalPrice,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              // If the checkout lock is unsuccessful, you might want to show an error message
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Test User. Cannot Checkout Items.'),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                              );
                                            }
                                          }).catchError((error) {
                                            // Handle any errors here

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Test User. Cannot Checkout Items.'),
                                                backgroundColor:
                                                    Colors.redAccent,
                                              ),
                                            );
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Error: Cart Id Not Found'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Center(
                                              // Wrap the Text widget with Center
                                              child: Text(
                                                'Store Will Open at $storeOpenTime.',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign
                                                    .center, // Center-align the text
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.deepPurpleAccent,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      surfaceTintColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shadowColor:
                                          Colors.white.withOpacity(0.8),

                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                            fontWeight: FontWeight
                                                .bold, // Making the font bold
                                          ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            20.0), // Slightly more rounded
                                      ),
                                      elevation:
                                          5, // Adding some shadow for depth
                                      side: const BorderSide(
                                          color: Colors.white,
                                          width:
                                              1), // Border for a more defined look
                                    ),
                                    child: Center(
                                        child: !(cart.isEmpty())
                                            ? (storeOpen
                                                ? Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 30,
                                                                vertical: 15),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.pinkAccent,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          boxShadow: const [],
                                                          border: Border.all(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1.0),
                                                        ),
                                                        child: Text(
                                                          'Complete Payment',
                                                          style: TextStyle(
                                                              fontSize: 22,
                                                              color:
                                                                  Colors.white),
                                                        ), // Consistent text size
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Center(
                                                        child: Text(
                                                          '\u{20B9}${cart.totalPrice}',
                                                          style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                      )
                                                    ],
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 30,
                                                                vertical: 15),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.pinkAccent,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          boxShadow: const [],
                                                          border: Border.all(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1.0),
                                                        ),
                                                        child: Text(
                                                          'Closed. Will Open @ $storeOpenTime',
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              color:
                                                                  Colors.white),
                                                        ), // Consistent text size
                                                      ),
                                                    ],
                                                  ))
                                            : Container(
                                                color: Colors.white,
                                              )),
                                  )),
                            ],
                          )
                        : Container()),

            // Return an empty SizedBox when no delivery address
          );
        } else {
          // Future is still loading, show a loading indicator or some placeholder
          return const Scaffold(
              body: Center(
            child: LinearProgressIndicator(),
          ));
        }
      },
    );
  }

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

class CartList extends StatefulWidget {
  CartList({super.key, required this.streetAddress, required this.isLoading});

  final String streetAddress;
  final bool isLoading;

  @override
  State<CartList> createState() => CartListState();
}

class CartListState extends State<CartList> {
  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    var itemNameStyle = Theme.of(context).textTheme.titleMedium;
    print("Cart items ${cart.items.length}");

    if (cart.isEmpty()) {
      return Center(
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(
                title: 'Otto Mart',
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [],
              border: Border.all(color: Colors.transparent, width: 1.0),
            ),
            child: const Text(
              'Add Items',
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold), // Consistent text size
            ),
          ),
        ),
      );
    } else {
      return Container(
        //Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4), // Rounded corners
          boxShadow: const [],
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 1), // Changes position of shadow
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
                child: Column(
                  children: [
                    for (var item in cart.items)
                      Container(
                        //padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Container(
                                decoration: const BoxDecoration(
                                    // Add border
                                    ),
                                child: Center(
                                  child: Image.network(
                                    item.image,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return Container(
                                        height: 50,
                                        color: Colors.grey[200],
                                        alignment: Alignment.center,
                                        child: const Center(
                                          child: Text(
                                            'no image',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Container(
                                decoration: const BoxDecoration(
                                    //border: Border.all( color: Colors.black), // Add border
                                    ),
                                child: Text(
                                  item.productName,
                                  style: itemNameStyle,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Container(
                                  decoration: BoxDecoration(
                                      color:
                                          Colors.deepPurpleAccent, // Add border
                                      borderRadius: BorderRadius.circular(8.0)),
                                  height:
                                      MediaQuery.of(context).size.height * 0.04,
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Spacer(),
                                        InkWell(
                                          onTap: () {
                                            final item2 = item;
                                            item2.quantity = -1;
                                            print(item);
                                            cart.addItemToCart(item2);
                                          },
                                          child: const Icon(
                                            Icons.horizontal_rule,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          item.quantity.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const Spacer(),
                                        InkWell(
                                          onTap: () {
                                            cart.addItemToCart(item);
                                          },
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 27,
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  )),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: const BoxDecoration(
                                    // Add border
                                    ),
                                child: Center(
                                  child: Text(
                                      "\u{20B9}${item.soldPrice * item.quantity}", // Replace with your price calculation
                                      style: itemNameStyle
                                      /*
                                        const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        */
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const TotalAmountSaved(),
              const SizedBox(height: 10),
              widget.isLoading
                  ? Container()
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: const Offset(
                                0, 1), // Changes position of shadow
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 13,
                              ),
                              RichText(
                                textAlign: TextAlign.center, // Center the text
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize:
                                        26, // Base font size for the whole text
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .black, // Base color for the whole text
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text:
                                          '5 Minute', // Part of the text you want to style differently
                                      style: TextStyle(
                                          color: Colors.deepPurpleAccent,
                                          fontSize: 28
                                          // Different color for this part
                                          // You can add more styles here if needed
                                          ),
                                    ),
                                    TextSpan(
                                      text:
                                          ' Delivery', // First part of the text
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\u{20B9} ${(cart.discount)}',
                                style: GoogleFonts.phudu(
                                    textStyle: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white)),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),

              const SizedBox(height: 5),
              Container(
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.3, 0.5],
                    colors: [Colors.white, Colors.lightGreenAccent],
                  ),
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 1), // Changes position of shadow
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 15,
                    ),
                    RichText(
                      textAlign: TextAlign.center, // Center the text
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 24, // Base font size for the whole text
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Base color for the whole text
                        ),
                        children: <TextSpan>[
                          TextSpan(
                              text:
                                  'Free Delivery above   \u{20B9}49 ', // Part of the text you want to style differently
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              /*
              const _DeliveryPartnerTip(),
              */
              _TaxAndDelivery(), // Add a separator
            ],
          ),
        ),
      );
    }
  }
}

class _TaxAndDelivery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1), // Changes position of shadow
          ),
        ],
        border: Border.all(color: Colors.white, width: 2.0),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
        child: Column(
          children: [
            _CustomListItem(
              icon: Icons.done_all_outlined,
              label: 'Item Total',
              amount: '${cart.totalPriceItems}',
              font: const TextStyle(fontSize: 16),
            ),
            cart.smallOrderFee > 0
                ? Padding(
                    padding:
                        const EdgeInsets.only(top: 5, left: 10.0, right: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.electric_bike_outlined, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              "Small Order Fee ",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "25", // Added a space for visual separation
                              style: const TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration
                                    .lineThrough, // This adds the line through effect
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.lightGreenAccent,
                                borderRadius: BorderRadius.circular(
                                    15), // Rounded corners
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 1), // Changes position of shadow
                                  ),
                                ],
                                border:
                                    Border.all(color: Colors.white, width: 2.0),
                              ),
                              child: Text(
                                "0 above 49", // Added a space for visual separation
                                style: const TextStyle(
                                  fontSize:
                                      14, // This adds the line through effect
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              right: 40, top: 0, bottom: 0),
                          child: Text(
                            cart.smallOrderFee.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 10.0, right: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.electric_bike_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Delivery Fee ",
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        "35", // Added a space for visual separation
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration
                              .lineThrough, // This adds the line through effect
                        ),
                      ),
                      cart.deliveryFee > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.lightGreenAccent,
                                borderRadius: BorderRadius.circular(
                                    15), // Rounded corners
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 1), // Changes position of shadow
                                  ),
                                ],
                                border:
                                    Border.all(color: Colors.white, width: 2.0),
                              ),
                              child: Text(
                                "0 above 49", // Added a space for visual separation
                                style: const TextStyle(
                                  fontSize:
                                      14, // This adds the line through effect
                                ),
                              ),
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 40, top: 0, bottom: 0),
                    child: Text(
                      cart.deliveryFee.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            cart.platformFee > 0
                ? Padding(
                    padding:
                        const EdgeInsets.only(top: 5, left: 10.0, right: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              "Platform Fee ",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "10", // Added a space for visual separation
                              style: const TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration
                                    .lineThrough, // This adds the line through effect
                              ),
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              right: 40, top: 0, bottom: 0),
                          child: Text(
                            cart.platformFee.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
            cart.packagingFee > 0
                ? _CustomListItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Packaging Fee',
                    amount: '${cart.packagingFee}',
                    font: const TextStyle(fontSize: 14),
                  )
                : Container(),
            cart.deliveryPartnerTip > 0
                ? _CustomListItem(
                    icon: Icons.volunteer_activism_outlined,
                    label: 'Delivery Partner Tip',
                    amount: '${cart.deliveryPartnerTip}',
                    font: const TextStyle(fontSize: 14),
                  )
                : Container(),
            const Divider(),
            _CustomListItem(
              icon: Icons.payments,
              label: 'To Pay',
              amount: '\u{20B9}${cart.totalPrice}',
              font: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class TotalAmountSaved extends StatelessWidget {
  const TotalAmountSaved({super.key});

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.3, 0.5],
          colors: [Colors.white, Colors.lightGreenAccent],
        ),
        borderRadius: BorderRadius.circular(10), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1), // Changes position of shadow
          ),
        ],
        border: Border.all(color: Colors.white, width: 2.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 13,
          ),
          Text('Total Saved',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400)),
          const SizedBox(
            width: 33,
          ),
          Text(
            '\u{20B9} ${(cart.discount)}',
            style: GoogleFonts.phudu(
                textStyle: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: Colors.black)),
          )
        ],
      ),
    );
  }
}

class _DeliveryPartnerTip extends StatefulWidget {
  const _DeliveryPartnerTip();

  @override
  State<_DeliveryPartnerTip> createState() => _DeliveryPartnerTipState();
}

class _DeliveryPartnerTipState extends State<_DeliveryPartnerTip> {
  int selectedTipIndex = -1;
  List<int> tipOptions = [10, 20, 35];
  TextEditingController customTipController = TextEditingController();
  bool showCustomTipField = false;

  @override
  void dispose() {
    customTipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 7),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Partner Tip',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8,
                children: [
                  ...tipOptions.map((tip) {
                    int index = tipOptions.indexOf(tip);
                    return ChoiceChip(
                      label: Text('$tip'),
                      selected: selectedTipIndex == index,
                      onSelected: (selected) {
                        setState(() {
                          selectedTipIndex = selected ? index : -1;
                          showCustomTipField = false;
                          cart.deliveryPartnerTip = tip;
                          customTipController.clear();
                        });
                      },
                      selectedColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20), // Adjust the radius as needed
                      ),
                    );
                  }).toList(),
                  ChoiceChip(
                    label: const Text('Other'),
                    selected: showCustomTipField,
                    onSelected: (selected) {
                      setState(() {
                        showCustomTipField = selected;
                        selectedTipIndex = -1;
                      });
                    },
                    selectedColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          20), // Adjust the radius as needed
                    ),
                  ),
                  if (showCustomTipField)
                    SizedBox(
                      width: 150,
                      child: Column(
                        children: [
                          TextField(
                            controller: customTipController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Enter Tip Amount',
                            ),
                            onSubmitted: (value) {
                              final tipAmount = int.tryParse(value);
                              if (tipAmount != null) {
                                setState(() {
                                  // Update the tip amount and other states accordingly
                                  cart.deliveryPartnerTip = tipAmount;
                                  selectedTipIndex = tipOptions
                                      .length; // Set to the index of 'Other' chip
                                  showCustomTipField = false;
                                  customTipController.clear();
                                });
                              }
                            },
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final tipAmount =
                                  int.tryParse(customTipController.text);
                              if (tipAmount != null) {
                                setState(() {
                                  // Update the tip amount and other states accordingly
                                  cart.deliveryPartnerTip = tipAmount;
                                  selectedTipIndex = tipOptions
                                      .length; // Set to the index of 'Other' chip
                                  showCustomTipField = false;
                                });
                              }
                            },
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final TextStyle? font;

  const _CustomListItem({
    required this.icon,
    required this.label,
    required this.amount,
    this.font,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 10.0, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: font,
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(right: 40, top: 0, bottom: 0),
            child: Text(
              amount,
              style: font,
            ),
          ),
        ],
      ),
    );
  }
}

class LockStockResponse {
  final bool lock;
  final String sign;
  final String merchantTransactionID;

  LockStockResponse(
      {required this.lock,
      required this.sign,
      required this.merchantTransactionID});

  // Factory constructor to create an instance from JSON.
  factory LockStockResponse.fromJson(Map<String, dynamic> json) {
    return LockStockResponse(
      lock: json['lock'] as bool,
      sign: json['sign'] as String,
      merchantTransactionID: json['merchantTransactionId'] as String,
    );
  }

  // Method to convert the object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'lock': lock,
      'sign': sign,
      'merchantTransactionId': merchantTransactionID
    };
  }
}
