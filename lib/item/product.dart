import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:provider/provider.dart';

class Product extends StatelessWidget {
  final String productName; // Add this variable to store the product name
  final int productId;
  final int price;

  const Product(
      {Key? key,
      required this.productName,
      required this.productId,
      required this.price})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>(); // Access the CartModel instance

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const CustomAppBar(),
      body: Center(
        child: Align(
          alignment: Alignment
              .topCenter, // Align the card and button to the top and center
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Card(
                elevation: 5,
                shadowColor: Colors.transparent,
                color: Colors.white,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 15.0, right: 15.0, top: 0),
                    child: Column(
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          price.toString(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ), // Add spacing between the card and the button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.height *
                    0.06, // Set the width of the button to 300
                child: ElevatedButton(
                  onPressed: () {
                    // Add your button logic here
                    final cartItem = CartItem(
                      productId: productId.toString(),
                      productName: productName,
                      price: price,
                      quantity: 1,
                    );
                    cart.addItemToCart(cartItem);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          12.0), // Adjust the value for squareness
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, // Adjust the horizontal padding
                      vertical: 8.0, // Adjust the vertical padding
                    ),
                  ),
                  child: const Text('Add To Cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                      // Your notifications icon logic here
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyCart()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        toolbarHeight: 130,
      ),
    );
  }
}
