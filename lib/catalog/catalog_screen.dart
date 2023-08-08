// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:provider/provider.dart';

class MyCatalog extends StatelessWidget {
  final String categoryName;
  const MyCatalog({required this.categoryName, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          categoryName: categoryName,
        ),
        body: ListOfItems(myString: categoryName));
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String categoryName;
  const CustomAppBar({required this.categoryName, Key? key}) : super(key: key);

  @override
  Size get preferredSize =>
      const Size.fromHeight(80); // Increased height to accommodate content

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // GestureDetector captures taps on the screen
      onTap: () {
        // When a tap is detected, reset the focus
        FocusScope.of(context).unfocus();
      },
      child: AppBar(
        backgroundColor: //Colors.deepPurpleAccent.shade100,
            Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  // GestureDetector captures taps on the input field
                  onTap: () {
                    // Prevent the focus from being triggered when tapping on the input field
                    // The empty onTap handler ensures that the tap event is captured here
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    height: 50, // Increased height to contain the input field
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            // Your search logic here
                          },
                        ),
                        Expanded(
                          child: TextField(
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search Groceries',
                              border: InputBorder.none,
                            ),
                            // Add your custom logic for handling text input, if needed.
                            // For example, you can use the onChanged callback to get the typed text.
                            onChanged: (text) {
                              // Your custom logic here
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.1,
                  child: IconButton(
                      padding: const EdgeInsets.only(right: 15.0),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MyCart()));
                      }),
                )
              ],
            ),
          ],
        ),
        toolbarHeight: 130,
        // Add any other actions or widgets to the AppBar if needed.
        // For example, you can use actions to add buttons or icons.
      ),
    );
  }
}

class ListOfItems extends StatelessWidget {
  final String myString;

  // Constructor for the widget that takes the string as a parameter
  const ListOfItems({required this.myString, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 0, top: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            myString,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First section consuming 3 columns
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.0),
                      borderRadius: BorderRadius.circular(
                          4.0), // Optional: Add rounded corners
                    ),
                    child: ListView(
                      shrinkWrap: true, // Add this line to remove the padding
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Center(
                              child: Text(
                            'Fresh Fruits',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          )),
                          onTap: () {
                            // Handle tile tap
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Center(
                            child: Text(
                              'Vegetables',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          onTap: () {
                            // Handle tile tap
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Center(
                            child: Text(
                              "Packaged Foods",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          onTap: () {
                            // Handle tile tap
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Center(
                              child: Text(
                            'Frozen Foods',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          )),
                          onTap: () {
                            // Handle tile tap
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Second section consuming 7 columns
                Expanded(
                  flex: 8,
                  child: Container(
                    padding: EdgeInsets.zero,
                    color: const Color.fromARGB(255, 212, 187, 255),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              // Add your content for the left column here
                              // For example, you can use a ListView.builder to display a list of card-like tiles.
                              Expanded(
                                  child: GridView.count(
                                crossAxisCount: 2,
                                mainAxisSpacing:
                                    0.0, // Remove vertical spacing between items
                                crossAxisSpacing:
                                    0.0, // Remove horizontal spacing between items

                                children: List.generate(100, (index) {
                                  return ListItem(index: index);
                                }),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  final int index;
  const ListItem({required this.index, super.key});

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>(); // Access the CartModel instance

    return Card(
      color: Colors.white,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0),
      ),
      margin: const EdgeInsets.only(
        top: 1.0,
        left: 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text('Tile $index'),
          ),
          const Spacer(), // Space filler to push the Price and Button to the bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'Price',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(1),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    final cartItem = CartItem(
                      productId: '$index',
                      productName: 'List Tile $index',
                      price: index,
                      quantity: 1,
                    );
                    cart.addItemToCart(cartItem);
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
