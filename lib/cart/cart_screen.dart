// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pronto/cart/address/screen/saved_address.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/payments/payments_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MyCart extends StatefulWidget {
  const MyCart({super.key});

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
          child: const Text(
            'Otto Cart',
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
          ? BottomAppBar(
              height: MediaQuery.of(context).size.height * 0.15,
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
                  textStyle: Theme.of(context).textTheme.titleLarge,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
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
            )
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
              height: MediaQuery.of(context).size.height * 0.18,
              child: Column(
                // Align children at the start
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
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
                            child: Text(
                                "Address: ${cart.deliveryAddress.streetAddress}")),
                        Expanded(
                          flex: 8,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SavedAddressScreen(),
                                ),
                              );
                            },
                            child: const Text("Change Address"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                        left: 12, right: 12, bottom: 8, top: 2),
                    height: MediaQuery.of(context).size.height * (0.18 - 0.065),
                    child: ElevatedButton(
                      onPressed: () {
                        // Make sure to get the actual cart ID from your cart variable or state
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        textStyle: Theme.of(context).textTheme.titleLarge,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cart.totalPrice.toString()),
                          const Text(" | "),
                          const Icon(Icons.payments_outlined),
                          const SizedBox(width: 10),
                          const Text('Complete Payment'),
                        ],
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
    var itemNameStyle = Theme.of(context).textTheme.titleSmall;

    if (cart.isEmpty()) {
      return const Center(
        child: Text(
          'Your Cart is Empty',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
      );
    } else {
      return Container(
        color: //const Color.fromARGB(255, 255, 158,            190),
            Theme.of(context).colorScheme.inversePrimary, //Colors.white,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                child: Column(
                  children: [
                    for (var item in cart.items)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(4.0)),
                          padding: const EdgeInsets.all(11.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Container(
                                  decoration: const BoxDecoration(
                                      // Add border
                                      ),
                                  child: Center(
                                      child: Image.network(item.image,
                                          height: 45)),
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
                                flex: 3,
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors
                                            .deepPurpleAccent, // Add border
                                        borderRadius:
                                            BorderRadius.circular(3.0)),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
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
                                            ),
                                          ),
                                          Text(
                                            item.quantity.toString(),
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              cart.addItemToCart(item);
                                            },
                                            child: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                            ),
                                          ),
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
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              const TotalAmountSaved(),
              const SizedBox(height: 5),
              const _DeliveryPartnerTip(),
              const SizedBox(height: 5),
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // Adjust the radius as needed
      ),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(right: 0),
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
        child: Column(
          children: [
            _CustomListItem(
              icon: Icons.done_all_outlined,
              label: 'Item Total',
              amount: '${cart.totalPriceItems}',
              font: Theme.of(context).textTheme.titleSmall,
            ),
            cart.smallOrderFee > 0
                ? _CustomListItem(
                    icon: Icons.donut_small_rounded,
                    label: 'Small Order Fee',
                    amount: '${cart.smallOrderFee}',
                    font: Theme.of(context).textTheme.titleSmall,
                  )
                : Container(),
            _CustomListItem(
              icon: Icons.electric_bike_outlined,
              label: 'Delivery Fee',
              amount: '${cart.deliveryFee}',
              font: Theme.of(context).textTheme.titleSmall,
            ),
            _CustomListItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Platform Fee',
              amount: '${cart.platformFee}',
              font: Theme.of(context).textTheme.titleSmall,
            ),
            _CustomListItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Packaging Fee',
              amount: '${cart.packagingFee}',
              font: Theme.of(context).textTheme.titleSmall,
            ),
            cart.deliveryPartnerTip > 0
                ? _CustomListItem(
                    icon: Icons.volunteer_activism_outlined,
                    label: 'Delivery Partner Tip',
                    amount: '${cart.deliveryPartnerTip}',
                    font: Theme.of(context).textTheme.titleSmall,
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
          border: Border.all(color: Colors.white, width: 1.0)),
      padding: const EdgeInsets.symmetric(horizontal: 15),
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
