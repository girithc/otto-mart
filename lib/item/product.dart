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

    return Scaffold(
      //resizeToAvoidBottomInset: false,
      appBar: const CustomAppBar(
        categoryName: 'Pronto',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //Image
            Container(
              height: MediaQuery.of(context).size.height * 0.30,
              padding: const EdgeInsets.all(5),
              child: Image.network(image),
            ),
            //Add To Cart Button
            Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width * 0.97,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Add this to prevent overflow.
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
                                  horizontal: 8, vertical: 4),
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
                                color: Colors.pinkAccent, fontSize: 18),
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
                              fontSize: 14,
                            ),
                          )),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.only(left: 12.0, top: 10, bottom: 0.0),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Bhagirathi',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 10.0),
                    alignment: Alignment.centerLeft,
                    child:
                        Text(productName, style: const TextStyle(fontSize: 18)),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 10.0),
                    alignment: Alignment.centerLeft,
                    child: const Text('100g',
                        style: TextStyle(fontSize: 13, color: Colors.black54)),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 10.0, top: 8),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          '\u{20B9}$price',
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '\u{20B9}${price * 1.2}',
                          style: const TextStyle(
                            fontSize: 15,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.deepPurpleAccent,
                          ),
                          child: Text(
                            '\u{20B9}${price * 0.2} Off',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15), // Use this for minimal spacing
                  const Divider(
                    height: 0,
                  ),
                  const ExpansionTile(
                    title: Text("About This Product",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Text("Info"),
                      )
                    ],
                  ),
                  const Divider(
                    height: 0,
                  ),
                  const SizedBox(
                    height: 5,
                  )
                ],
              ),
            ),
            //Related Products
            Container(
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Colors.white, Color.fromARGB(255, 251, 226, 255)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                        left: 19.0, top: 8.0, bottom: 8.0),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "You might also like",
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const HorizontalScrollItems(),
                ],
              ),
            ),
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
              Flexible(
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
                  child: cart.numberOfItems > 0
                      ? (cart.numberOfItems > 1
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_cart_outlined),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text('${cart.numberOfItems.toString()} Items'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_cart_outlined),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text('${cart.numberOfItems.toString()} Item'),
                              ],
                            ))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined),
                            SizedBox(
                              width: 10,
                            ), // Add your desired icon here
                            // Add some spacing between the icon and text
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

class TabBarApp extends StatelessWidget {
  const TabBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const TabBarExample(),
    );
  }
}

class TabBarExample extends StatelessWidget {
  const TabBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TabBar Sample'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.cloud_outlined),
              ),
              Tab(
                icon: Icon(Icons.beach_access_sharp),
              ),
              Tab(
                icon: Icon(Icons.brightness_5_sharp),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            Center(
              child: Text("It's cloudy here"),
            ),
            Center(
              child: Text("It's rainy here"),
            ),
            Center(
              child: Text("It's sunny here"),
            ),
          ],
        ),
      ),
    );
  }
}
