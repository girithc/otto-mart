import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/search/search_screen.dart';
import 'package:provider/provider.dart';

class Product extends StatelessWidget {
  final String productName; // Add this variable to store the product name
  final int productId;
  final int price;
  final int stockQuantity;
  final String image;

  const Product(
      {Key? key,
      required this.productName,
      required this.productId,
      required this.price,
      required this.stockQuantity,
      required this.image})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>(); // Access the CartModel instance
    final itemDescription = <String>[
      'Description : Item Description',
      'Country of Origin : India'
    ]; // Creates growable list.

    return Scaffold(
      //resizeToAvoidBottomInset: false,
      appBar: const CustomAppBar(
        categoryName: 'Pronto',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              padding: const EdgeInsets.all(5),
              child: Image.network(image),
            ),
            Container(
                height: 600,
                width: MediaQuery.of(context).size.width * 0.97,
                margin: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.015),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border:
                      Border.all(color: Colors.deepPurpleAccent, width: 2.0),
                  // Add this line to set the blue border
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              final cartItem = CartItem(
                                  productId: productId.toString(),
                                  productName: productName,
                                  price: price,
                                  quantity: 1,
                                  stockQuantity: stockQuantity,
                                  image: image);
                              cart.addItemToCart(cartItem);
                            },
                            style: ElevatedButton.styleFrom(
                                surfaceTintColor: Colors.white,
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                side: const BorderSide(
                                  width: 1.0,
                                  color: Colors.pinkAccent,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                )),
                            child: const Text(
                              'Add To Cart +',
                              style: TextStyle(
                                  color: Colors.pinkAccent, fontSize: 20),
                            )),
                        ElevatedButton(
                            onPressed: () {
                              final cartItem = CartItem(
                                  productId: productId.toString(),
                                  productName: productName,
                                  price: price,
                                  quantity: 1,
                                  stockQuantity: stockQuantity,
                                  image: image);
                              cart.addItemToCart(cartItem);
                            },
                            style: ElevatedButton.styleFrom(
                                surfaceTintColor: Colors.white,
                                backgroundColor: Colors.pinkAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 5),
                                side: const BorderSide(
                                  width: 1.0,
                                  color: Colors.pinkAccent,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                )),
                            child: Text(
                              '\u{20B9}$price',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            )),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 2.5),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Brand',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 2.5),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        productName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 2.5),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Quantity',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 2.5,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Text(
                            'Price:',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '\u{20B9}$price',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(
                              width: 5), // Add some spacing between the prices
                          Text(
                            '\u{20B9}${price * 1.2}', // Replace XXX with your original price
                            style: const TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration
                                  .lineThrough, // Add the strikethrough decoration
                              decorationColor: Colors
                                  .red, // Customize the strikethrough color
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 40,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: itemDescription.length,
                        itemExtent: 30,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            margin: EdgeInsets
                                .zero, // Adjust the vertical spacing here
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    alignment: Alignment.topLeft,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 10),
                                    child: Text(
                                      itemDescription[index],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  )
                                ]),
                          );
                        },
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        child: Container(
          margin: EdgeInsets.zero,
          child: Row(
            // Expand the Row to fill the available space
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 5,
                child: CarouselSlider(
                  options: CarouselOptions(
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 3.5,
                      viewportFraction: 0.95),
                  items: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.pinkAccent),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Center(
                        child: Text("Offer 1"),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.pinkAccent),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Center(
                        child: Text("Offer 2"),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.pinkAccent),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Center(
                        child: Text("Offer 3"),
                      ),
                    ),
                    // Add more items as needed
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyCart()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons
                          .shopping_cart_outlined), // Add your desired icon here
                      SizedBox(
                          width:
                              10), // Add some spacing between the icon and text
                      Text('Cart'),
                    ],
                  ),
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
        elevation: 1.0,
        backgroundColor: //Colors.deepPurpleAccent.shade100,
            Colors.white, //Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.71,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.deepPurpleAccent,
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 0.0),
                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
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
                        child: GestureDetector(
                          onTap: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SearchTopLevel()),
                            )
                          },
                          child: const AbsorbPointer(
                            absorbing: true,
                            child: TextField(
                              readOnly: true,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search For Groceries',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
