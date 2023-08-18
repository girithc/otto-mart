// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:provider/provider.dart';

class MyCart extends StatelessWidget {
  const MyCart({super.key});

  @override
  Widget build(BuildContext context) {
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
            'Pronto',
            style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        elevation: 4.0,
        backgroundColor: //Colors.deepPurpleAccent.shade100,
            Colors.white,
        foregroundColor: Colors.deepPurple,
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
            const Divider(height: 4, color: Colors.black),
          ],
        ),
      ),
      bottomNavigationBar: const BottomAppBar(
        height: 100,
        child: Text('BAR'),
      ),
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
        color: const Color.fromARGB(255, 255, 158,
            190), //Theme.of(context).colorScheme.inversePrimary, //Colors.white,
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
                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
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
                                    child: Text(
                                      'Image',
                                      style: itemNameStyle,
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
                              const Expanded(
                                flex: 1,
                                child: SizedBox(width: 10),
                              ),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: const BoxDecoration(
                                      // Add border
                                      ),
                                  child: Center(
                                    child: Text(
                                      "\$${item.price * item.quantity}", // Replace with your price calculation
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                      ),
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
              amount: '\$${cart.totalPriceItems}',
              font: Theme.of(context).textTheme.titleSmall,
            ),
            _CustomListItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Packaging Fee',
              amount: '${cart.packagingFee}',
              font: Theme.of(context).textTheme.titleSmall,
            ),
            _CustomListItem(
              icon: Icons.electric_bike_outlined,
              label: 'Delivery Fee',
              amount: '${cart.deliveryFee}',
              font: Theme.of(context).textTheme.titleSmall,
            ),
            _CustomListItem(
              icon: Icons.volunteer_activism_outlined,
              label: 'Delivery Partner Tip',
              amount: '${cart.deliveryPartnerTip}',
              font: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(),
            _CustomListItem(
              icon: Icons.payments,
              label: 'To Pay',
              amount: '${cart.totalPrice}',
              font: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
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

class _CartTotal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var hugeStyle =
        Theme.of(context).textTheme.displayLarge!.copyWith(fontSize: 48);

    var cart = context.watch<CartModel>();

    return Container(
      color: Colors.white,
      height: 125,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('\$${cart.totalPrice}', style: hugeStyle),
            const SizedBox(width: 24),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Buying not supported yet.')));
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('BUY'),
            ),
          ],
        ),
      ),
    );
  }
}
