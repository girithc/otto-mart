// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pronto/cart/address/screen/saved_address.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/payments/payments_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MyCart extends StatefulWidget {
  const MyCart({super.key});
  static const String routeName = '/myCart';

  @override
  State<MyCart> createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  Future<bool> checkoutLockItems(int cartId) async {
    const String apiUrl = '$baseUrl/checkout-lock-items';
    final Map<String, dynamic> payload = {'cart_id': cartId};
    print("Check-out-lock-items");
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
        print(
            'Request failed with status: ${response.statusCode}. ${response.body}');
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
    bool hasDeliveryAddress = !cart.deliveryAddress.isEmpty();

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.0,
                  colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                  tileMode: TileMode.mirror)
              .createShader(bounds),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyHomePage(title: "Otto Mart")),
              );
            },
            child: const Text(
              'Otto Cart',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        elevation: 4.0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: _CartList(),
              ),
            ),
            //const Divider(height: 4, color: Colors.black),
          ],
        ),
      ),
      bottomNavigationBar: !hasDeliveryAddress
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 10,
                    offset: Offset(0, 5), // Specify the shadow's offset
                  ),
                ],
              ),
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              height: MediaQuery.of(context).size.height * 0.15,
              child: Column(
                  // Align children at the start
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, bottom: 20, top: 0),
                      height:
                          MediaQuery.of(context).size.height * (0.18 - 0.065),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedAddressScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          textStyle:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    fontWeight:
                                        FontWeight.bold, // Making the font bold
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 10,
                    offset: Offset(0, 5), // Specify the shadow's offset
                  ),
                ],
              ),
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              height: MediaQuery.of(context).size.height * 0.15,
              child: Column(
                // Align children at the start
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /*
                  Container(
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    height: MediaQuery.of(context).size.height * 0.065,
                    decoration: BoxDecoration(
                        border: Border.all(
                            style: BorderStyle.solid, color: Colors.white)),
                    child: Row(
                      children: [
                        const Expanded(flex: 1, child: SizedBox()),
                        Expanded(
                          flex: 8,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.05,
                            padding: const EdgeInsets.all(
                                0), // Add some padding inside the container
                            decoration: BoxDecoration(
                              color: Colors
                                  .white, // Background color of the container
                              borderRadius:
                                  BorderRadius.circular(15), // Rounded corners
                              boxShadow: [
                                // Optional shadow for a subtle "raised" effect
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "Address: ${cart.deliveryAddress.streetAddress}",
                                style: const TextStyle(
                                  fontSize: 14, // Optional: Adjust font size
                                  color: Colors
                                      .black, // Optional: Adjust text color
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 8,
                          child: Container(
                            margin:
                                const EdgeInsets.only(right: 12.0, left: 16.0),
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
                                foregroundColor: Colors.deepPurpleAccent,
                                backgroundColor: Colors.white,
                                surfaceTintColor:
                                    Colors.white, // Text and icon color
                                elevation: 5, // Shadow depth
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 5),
                              ),
                              child: const Text(
                                "Change Address",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  */
                  Container(
                    padding: const EdgeInsets.only(
                        left: 12, right: 12, bottom: 20, top: 0),
                    height: MediaQuery.of(context).size.height * (0.18 - 0.065),
                    child: ElevatedButton(
                      onPressed: () {
                        // Make sure to get the actual cart ID from your cart variable or state
                        if (cart.isEmpty()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyHomePage(
                                title: 'Otto Mart',
                              ),
                            ),
                          );
                        } else {
                          String? cartId = cart.cartId;
                          if (cartId != null) {
                            int cartIdInt = int.parse(cartId);
                            checkoutLockItems(cartIdInt).then((success) {
                              if (success) {
                                // If the checkout lock is successful, navigate to the PaymentsPage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PaymentsPage(),
                                  ),
                                );
                              } else {
                                // If the checkout lock is unsuccessful, you might want to show an error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Failed to lock items for checkout.'),
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
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        textStyle:
                            Theme.of(context).textTheme.titleLarge!.copyWith(
                                  fontWeight:
                                      FontWeight.bold, // Making the font bold
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
                      child: Center(
                        child: Text(
                          cart.isEmpty() ? 'Add Items' : 'Complete Payment',
                          style: const TextStyle(
                              fontSize: 24), // Consistent text size
                        ),
                      ),
                    ),
                  ),

                  // ... other children of the Column ...
                ],
              ),
            ),
      // Return an empty SizedBox when no delivery address
    );
  }
}

class _CartList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    var itemNameStyle = Theme.of(context).textTheme.titleMedium;

    if (cart.isEmpty()) {
      return const Center(
        child: Text(
          'Your Cart is Empty',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
      );
    } else {
      return Container(
        //Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2), // Changes position of shadow
            ),
          ],
          border: Border.all(color: Colors.white, width: 1.0),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 5),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2), // Changes position of shadow
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 1.0),
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
                                    child:
                                        Image.network(item.image, height: 75)),
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
                                            context
                                                .read<CartModel>()
                                                .removeItem(
                                                    itemId: item.productId);
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
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2), // Changes position of shadow
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.0),
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
                ? _CustomListItem(
                    icon: Icons.donut_small_rounded,
                    label: 'Small Order Fee',
                    amount: '${cart.smallOrderFee}',
                    font: const TextStyle(fontSize: 16),
                  )
                : Container(),
            _CustomListItem(
              icon: Icons.electric_bike_outlined,
              label: 'Delivery Fee',
              amount: '${cart.deliveryFee}',
              font: const TextStyle(fontSize: 16),
            ),
            _CustomListItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Platform Fee',
              amount: '${cart.platformFee}',
              font: const TextStyle(fontSize: 16),
            ),
            _CustomListItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Packaging Fee',
              amount: '${cart.packagingFee}',
              font: const TextStyle(fontSize: 16),
            ),
            cart.deliveryPartnerTip > 0
                ? _CustomListItem(
                    icon: Icons.volunteer_activism_outlined,
                    label: 'Delivery Partner Tip',
                    amount: '${cart.deliveryPartnerTip}',
                    font: const TextStyle(fontSize: 16),
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
          colors: [Colors.white, Colors.deepPurpleAccent],
        ),
        borderRadius: BorderRadius.circular(15), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2), // Changes position of shadow
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.0),
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
          Text(
            'Total Saved',
            style: GoogleFonts.phudu(textStyle: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(
            width: 33,
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
