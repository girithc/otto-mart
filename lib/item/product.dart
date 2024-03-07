import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/search/search_screen.dart';
import 'package:provider/provider.dart';

class Product extends StatefulWidget {
  final String productName;
  final int productId;
  final int mrpPrice;
  final int storePrice;
  final int discount;
  final int stockQuantity;
  final String image;
  final String brand;
  final int quantity;
  final String unitOfQuantity;

  const Product({
    Key? key,
    required this.productName,
    required this.productId,
    required this.mrpPrice,
    required this.storePrice,
    required this.discount,
    required this.stockQuantity,
    required this.image,
    required this.brand,
    required this.quantity,
    required this.unitOfQuantity,
  }) : super(key: key);

  @override
  State<Product> createState() => _ProductState();
}

class _ProductState extends State<Product> {
  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>(); // Access the CartModel instance
    var itemIndexInCart = cart.items
        .indexWhere((item) => item.productId == widget.productId.toString());

    return Scaffold(
      appBar: const CustomAppBar(
        categoryName: 'Pronto',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carousel
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.30,
              child: CarouselSlider.builder(
                itemCount: 3, // Display the image 3 times, adjust as needed
                itemBuilder:
                    (BuildContext context, int itemIndex, int pageViewIndex) {
                  return Image.network(
                    widget.image,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.30,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Center(
                          child: Text(
                            'no image',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  );
                },
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height * 0.30,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enableInfiniteScroll: true,
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  viewportFraction: 0.8,
                  onPageChanged: (index, reason) {
                    // Handle change if needed
                  },
                ),
              ),
            ),
            //Add To Cart Button
            Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width * 0.97,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Add this to prevent overflow.
                children: [
                  const SizedBox(height: 10),
                  (itemIndexInCart != -1)
                      ? Container(
                          width: 150,
                          height: 45,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white, // Add border
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  cart.addItemToCart(CartItem(
                                      productId: widget.productId.toString(),
                                      productName: widget.productName,
                                      price: widget.mrpPrice,
                                      soldPrice: widget.storePrice,
                                      quantity: -1,
                                      stockQuantity: widget.stockQuantity,
                                      image: widget.image));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurpleAccent,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: const Icon(
                                    Icons.horizontal_rule,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  '0',
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 26),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  cart.addItemToCart(CartItem(
                                      productId: widget.productId.toString(),
                                      productName: widget.productName,
                                      price: widget.mrpPrice,
                                      soldPrice: widget.storePrice,
                                      quantity: 1,
                                      stockQuantity: widget.stockQuantity,
                                      image: widget.image));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurpleAccent,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  final cartItem = CartItem(
                                      productId: widget.productId.toString(),
                                      productName: widget.productName,
                                      price: widget.storePrice,
                                      soldPrice: widget.storePrice,
                                      quantity: 1,
                                      stockQuantity: widget.stockQuantity,
                                      image: widget.image);
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
                                ),
                              ),
                              ElevatedButton(
                                  onPressed: () {
                                    final cartItem = CartItem(
                                        productId: widget.productId.toString(),
                                        productName: widget.productName,
                                        price: widget.storePrice,
                                        soldPrice: widget.storePrice,
                                        quantity: 1,
                                        stockQuantity: widget.stockQuantity,
                                        image: widget.image);
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
                                    '\u{20B9}${widget.storePrice}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  )),
                            ],
                          ),
                        ),
                  Container(
                    padding:
                        const EdgeInsets.only(left: 12.0, top: 10, bottom: 0.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.brand,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 10.0),
                    alignment: Alignment.centerLeft,
                    child: Text(widget.productName,
                        style: const TextStyle(fontSize: 18)),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 10.0),
                    alignment: Alignment.centerLeft,
                    child: Text('${widget.quantity}${widget.unitOfQuantity}',
                        style:
                            const TextStyle(fontSize: 15, color: Colors.black)),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 10.0, top: 8),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          '\u{20B9}${widget.storePrice}',
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '\u{20B9}${widget.mrpPrice}',
                          style: const TextStyle(
                            fontSize: 15,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 10),
                        widget.discount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0, vertical: 3.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.deepPurpleAccent,
                                ),
                                child: Text(
                                  '\u{20B9}${widget.discount} OFF',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 15),
                                ),
                              )
                            : SizedBox.shrink(),
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
                        padding: EdgeInsets.only(bottom: 25),
                        child: Text("Description Coming Soon"),
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
              Flexible(
                flex: 5,
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
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: cart.itemList.isNotEmpty
                      ? (cart.itemList.length > 1
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SearchTopLevel()),
                          );
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
