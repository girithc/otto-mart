import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:pinput/pinput.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/item/product.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:pronto/search/constants.dart';
import 'package:pronto/search/search_data.dart';
import 'package:pronto/search/search_item.dart';
import 'package:provider/provider.dart';

class SearchTopLevel extends StatefulWidget {
  const SearchTopLevel({super.key});

  @override
  State<SearchTopLevel> createState() => _SearchTopLevelState();
}

class _SearchTopLevelState extends State<SearchTopLevel> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SearchData(),
        )
      ],
      child: SearchPage(searchFocusNode: FocusNode()),
    );
  }
}

class SearchPage extends StatefulWidget {
  final FocusNode searchFocusNode;

  const SearchPage({required this.searchFocusNode, Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  void initState() {
    super.initState();
    widget.searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchData = context.watch<SearchData>();
    final searchQuery = searchData.searchQuery;
    var cart = context.watch<CartModel>();

    return Scaffold(
      appBar: CustomAppBar(
          categoryName: 'Pronto', searchFocusNode: widget.searchFocusNode),
      body: searchQuery.isNotEmpty
          ? const SearchItemList()
          : const TypingAnimation(),
      //: const SearchTemplate(),
      bottomNavigationBar: Container(
        padding:
            const EdgeInsets.only(bottom: 25, left: 10, right: 10, top: 10),
        margin: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              flex: 8,
              child: CarouselSlider(
                items: [
                  // First tab
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.tealAccent,
                    ),
                    child: Center(
                      child: Text(
                        'Free Delivery Above 49',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Second tab
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.tealAccent,
                    ),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            // Default text style
                            color: Colors.black,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'FLAT 5', // The part you want to emphasize
                              style: TextStyle(
                                  fontSize:
                                      19.0), // Increase the font size for emphasis
                            ),
                            TextSpan(
                                text: ' to '), // Unchanged part of the text
                            TextSpan(
                              text:
                                  '50% Discount', // The second part you want to emphasize
                              style: TextStyle(
                                  fontSize:
                                      19.0), // Increase the font size for emphasis
                            ),
                            TextSpan(
                                text:
                                    ' on All Items'), // Unchanged part of the text
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height * 0.06,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  //aspectRatio: 16 / 9,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enableInfiniteScroll: true,
                  autoPlayAnimationDuration: Duration(
                    seconds: 3,
                  ),
                  viewportFraction: 0.95,
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: ElevatedButton(
                onPressed: () async {
                  const storage = FlutterSecureStorage();

                  // Read the cartId from storage
                  String? cartId = await storage.read(key: 'cartId');

                  // Check if cartId is null
                  if (cartId == null) {
                    // If cartId is null, navigate to MyPhone()
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyPhone()),
                    );
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyCart()));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
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
    );
  }
}

class TypingAnimation extends StatefulWidget {
  const TypingAnimation({super.key});

  @override
  _TypingAnimationState createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<TypingAnimation> {
  List<String> words = [
    "Real Juice",
    "Neutrogena",
    "Mamaearth",
    "Mango",
    "Maggi",
    "Toothbrush",
    "Slurrp Farm",
    "Sriracha"
  ];
  int index = 0;

  @override
  void initState() {
    super.initState();
    startTyping();
  }

  void startTyping() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        index = (index + 1) % words.length;
      });
      startTyping();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        //mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
          ),
          const Text(
            "Search for",
            style:
                TextStyle(fontSize: 36), // Adjusted font size for better layout
          ),
          const SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(0, 1), // changes position of shadow
                  ),
                ],
                borderRadius: BorderRadius.circular(10)),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                words[index],
                key: ValueKey<String>(words[index]),
                style: const TextStyle(
                    fontSize: 36, color: Colors.deepPurpleAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
Search Template Page
*/

class SearchTemplate extends StatefulWidget {
  const SearchTemplate({super.key});

  @override
  State<SearchTemplate> createState() => _SearchTemplateState();
}

class _SearchTemplateState extends State<SearchTemplate> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding:
                  const EdgeInsets.only(top: 15.0, bottom: 2.0, left: 10.0),
              child: const Text(
                'Popular Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const HorizontalScrollItems(),
            Container(
              alignment: Alignment.centerLeft,
              padding:
                  const EdgeInsets.only(top: 15.0, bottom: 2.0, left: 10.0),
              child: const Text(
                'Popular Brands',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const HorizontalScrollBrands(),
            const SizedBox(height: 10),
            const Highlights(),
          ],
        ),
      ),
    );
  }
}

class HorizontalScrollItems extends StatelessWidget {
  const HorizontalScrollItems({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        CarouselSlider(
          items: [
            GestureDetector(
              onTap: () {},
              child: Card(
                elevation: 1,
                shadowColor: Colors.grey,
                surfaceTintColor: Colors.white,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8.0), // Adjust the radius as needed
                ),
                child: SizedBox(
                  width: 300,
                  height: 500,
                  child: Stack(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Product-1',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: SizedBox(
                            height: 32,
                            width: 48,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shadowColor: Colors.white,
                                surfaceTintColor: Colors.white,
                                padding: const EdgeInsets.all(0),
                                side: const BorderSide(
                                  width: 1.0,
                                  color: Colors.deepPurpleAccent,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8.0), // Adjust the radius as needed
                                ),
                              ),
                              child: const Text(
                                'Add+',
                                style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Slider Container properties
          options: CarouselOptions(
            height: 155.0,
            enlargeCenterPage: false,
            autoPlay: false,
            aspectRatio: 6 / 9,
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.38,
          ),
        ),
      ],
    );
  }
}

class HorizontalScrollBrands extends StatelessWidget {
  const HorizontalScrollBrands({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        CarouselSlider(
          items: [
            GestureDetector(
              onTap: () {},
              child: Card(
                elevation: 1,
                shadowColor: Colors.grey,
                surfaceTintColor: Colors.white,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8.0), // Adjust the radius as needed
                ),
                child: SizedBox(
                    width: 300,
                    height: 500,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(20),
                      child: const Text('Brand Name'),
                    )),
              ),
            ),
          ],

          // Slider Container properties
          options: CarouselOptions(
            height: 120.0,
            enlargeCenterPage: false,
            autoPlay: false,
            aspectRatio: 6 / 9,
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.25,
          ),
        ),
      ],
    );
  }
}

class Highlights extends StatelessWidget {
  const Highlights({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        CarouselSlider(
          items: [
            GestureDetector(
              onTap: () {},
              child: Card(
                elevation: 1,
                shadowColor: Colors.grey,
                surfaceTintColor: Colors.white,
                color: Colors.purpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8.0), // Adjust the radius as needed
                ),
                child: SizedBox(
                    width: 300,
                    height: 500,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(20),
                      child: Text('Promotion',
                          style: GoogleFonts.lobster(
                            textStyle: const TextStyle(
                                color: Colors.white, fontSize: 24),
                          )),
                    )),
              ),
            ),
          ],

          // Slider Container properties
          options: CarouselOptions(
            height: 135.0,
            enlargeCenterPage: false,
            autoPlay: true,
            aspectRatio: 4 / 9,
            autoPlayCurve: Curves.fastOutSlowIn,
            autoPlayInterval: const Duration(seconds: 4),
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.85,
          ),
        ),
      ],
    );
  }
}
/*
Search Results
*/

class SearchItemList extends StatefulWidget {
  const SearchItemList({super.key});

  @override
  SearchItemListState createState() => SearchItemListState();
}

class SearchItemListState extends State<SearchItemList> {
  @override
  Widget build(BuildContext context) {
    final searchData = context.watch<SearchData>();
    final searchResults = searchData.searchResults;
    final searchQuery = searchData.searchQuery;

    // Use searchQuery to make API calls and update searchResults
    // Use searchResults to display the list of items

    return Column(
      children: [
        //const Chip(label: Text('apple')),
        Container(
          height: MediaQuery.of(context).size.height * 0.08,
          width: MediaQuery.of(context).size.width * 0.95,
          alignment: Alignment.centerLeft,
          color: Colors.white,
          //decoration: BoxDecoration(border: Border.all(color: Colors.black)),
          child: Chip(
            label: searchData.notFound
                ? RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                            text: 'no results for ',
                            style: TextStyle(
                                color: Colors
                                    .black) // or any other color you want for the rest of the text
                            ),
                        TextSpan(
                            text: searchQuery,
                            style: const TextStyle(
                                color: Colors.deepPurpleAccent)),
                      ],
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'search ',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: searchQuery,
                          style: const TextStyle(color: Colors.deepPurple),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.zero,
            decoration: const BoxDecoration(
              color: Colors.white,
            ), //const Color.fromARGB(255, 212, 187, 255),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 6.0,
                crossAxisSpacing: 6.0,
                childAspectRatio: 0.82,
              ),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return ListItem(
                  name: searchResults[index].name,
                  id: searchResults[index].id,
                  mrpPrice: searchResults[index].mrpPrice,
                  storePrice: searchResults[index].storePrice,
                  discount: searchResults[index].discount,
                  stockQuantity: searchResults[index].stockQuantity,
                  quantity: searchResults[index].quantity,
                  unitOfQuantity: searchResults[index].unitOfQuantity,
                  image: searchResults[index].image,
                  brand: searchResults[index].brand,
                  index: index % 2,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ListItem extends StatelessWidget {
  final String name;
  final int id;
  final int mrpPrice;
  final int storePrice;
  final int discount;
  final int stockQuantity;
  final int index;
  final String unitOfQuantity;
  final int quantity;
  final String image;
  final String brand;

  const ListItem(
      {super.key,
      required this.name,
      required this.id,
      required this.mrpPrice,
      required this.storePrice,
      required this.discount,
      required this.stockQuantity,
      required this.image,
      required this.index,
      required this.quantity,
      required this.unitOfQuantity,
      required this.brand});

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>(); // Access the CartModel instance
    var itemIndexInCart =
        cart.items.indexWhere((item) => item.productId == id.toString());
    return GestureDetector(
      onTap: () async {
        const storage = FlutterSecureStorage();

        // Read the cartId from storage
        String? cartId = await storage.read(key: 'cartId');

        // Check if cartId is null
        if (cartId == null) {
          // If cartId is null, navigate to MyPhone()
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyPhone()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Product(
                brand: brand,
                productName: name,
                productId: id,
                mrpPrice: mrpPrice,
                storePrice: storePrice,
                discount: discount,
                stockQuantity: stockQuantity,
                image: image,
                quantity: quantity,
                unitOfQuantity: unitOfQuantity,
              ),
            ),
          );
        }

        // Check if cartId is null
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400
                      .withOpacity(0.2), // Shadow color with some opacity
                  spreadRadius: 1, // Extent of the shadow
                  blurRadius: 1, // Blur effect
                  offset: const Offset(0, 1), // Changes position of shadow
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                      top: 2, bottom: 2, left: 2, right: 2),
                  height: MediaQuery.of(context).size.height * 0.15,
                  child: Center(
                    child: image.contains('.avif')
                        ? AvifImage.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context,
                                Object exception, StackTrace? stackTrace) {
                              return Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(color: Colors.white),
                                  boxShadow: const [],
                                ),
                                alignment: Alignment.center,
                                child: const Center(
                                  child: Text(
                                    'image',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black),
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context,
                                Object exception, StackTrace? stackTrace) {
                              return Container(
                                height: 120,
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const Center(
                                  child: Text(
                                    'no image',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  alignment: Alignment.centerLeft,
                  height: 37,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1.0),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    name,
                    maxLines: 2,
                    style: GoogleFonts.hind(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                  margin: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1.0),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    '$quantity $unitOfQuantity',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
                  ),
                ),
                //const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(left: 8.0),
                  height: 40,
                  margin: const EdgeInsets.only(top: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1.0),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$mrpPrice',
                              style: const TextStyle(
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.black54,
                              ),
                            ),
                            Text(
                              '\u{20B9}$storePrice',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ]),
                      itemIndexInCart != -1
                          ? Container(
                              width: 80,
                              height: 35,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.pinkAccent, // Add border
                                  borderRadius: BorderRadius.circular(10.0)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      cart.addItemToCart(CartItem(
                                          productId: id.toString(),
                                          productName: name,
                                          price: mrpPrice,
                                          soldPrice: storePrice,
                                          quantity: -1,
                                          stockQuantity: stockQuantity,
                                          image: image));
                                    },
                                    child: const Icon(
                                      Icons.horizontal_rule,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    cart.items[itemIndexInCart].quantity
                                        .toString(),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      cart.addItemToCart(CartItem(
                                          productId: id.toString(),
                                          productName: name,
                                          price: mrpPrice,
                                          soldPrice: storePrice,
                                          quantity: 1,
                                          stockQuantity: stockQuantity,
                                          image: image));
                                    },
                                    child: const Icon(
                                      Icons.add,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              width: 55,
                              padding: EdgeInsets.zero,
                              margin: const EdgeInsets.only(
                                  right: 2, top: 2, bottom: 4),
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Create an instance of FlutterSecureStorage
                                  const storage = FlutterSecureStorage();
                                  if (stockQuantity > 0) {
                                    // Read the cartId from storage
                                    String? cartId =
                                        await storage.read(key: 'cartId');

                                    final cartItem = CartItem(
                                      productId: id.toString(),
                                      productName: name,
                                      price: mrpPrice,
                                      soldPrice: storePrice,
                                      quantity: 1,
                                      stockQuantity: stockQuantity,
                                      image: image,
                                    );
                                    cart.addItemToCart(cartItem);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Center(
                                          child: Text(
                                            'Item Coming Soon !',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        backgroundColor: Colors.greenAccent,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    surfaceTintColor: Colors.white,
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.all(2),
                                    side: BorderSide(
                                      width: 1.0,
                                      color: stockQuantity <= 0
                                          ? Colors.greenAccent
                                          : Colors.pinkAccent,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    )),
                                child: stockQuantity <= 0
                                    ? Text(
                                        'Notify',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 13),
                                      )
                                    : Text(
                                        'Add',
                                        style: TextStyle(
                                            color: Colors.pinkAccent,
                                            fontSize: 13),
                                      ),
                              ),
                            )
                    ],
                  ),
                ),
              ],
            ),
          ),
          discount > 0
              ? Positioned(
                  top: 6, // Adjust the position as needed
                  left: 6, // Adjust the position as needed
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\u{20B9}$discount OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          if (stockQuantity <= 0)
            Container(
              height: MediaQuery.of(context).size.height * 0.155,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2), // Adjust padding as needed
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String categoryName;
  final FocusNode searchFocusNode;

  const CustomAppBar(
      {required this.categoryName, required this.searchFocusNode, Key? key})
      : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(82);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final SearchItemApiClient apiClient = SearchItemApiClient();
  final Logger _logger = Logger();

  List<Item> resultSearchItems = [];

  Future<void> fetchSearchItems(String queryString) async {
    try {
      if (queryString.length > 1) {
        final fetchedSearchItems =
            await apiClient.fetchSearchItems(queryString);
        setState(() {
          resultSearchItems = fetchedSearchItems;
          //print(resultSearchItems[1].name);
        });
      } else {
        _logger.e('Query String is small.');
      }
    } catch (err) {
      _logger.e('(catalog)fetchCategories error $err');
    }
  }

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final searchData = context.watch<SearchData>();

    return Material(
      elevation: 4.0,
      shadowColor: Colors.deepPurpleAccent,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.05,
        ),
        margin: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.deepPurpleAccent,
            width: 1.0, // Adjust the border width as needed
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Aligns children to the edges
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 1.0, // Adjust the border width as needed
                ),
              ),
              width: MediaQuery.of(context).size.width * 0.15,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_outlined,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: TextField(
                focusNode: widget.searchFocusNode,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
                controller: searchController,
                onChanged: (value) async {
                  searchData.updateSearchQuery(value);
                  if (value.isNotEmpty) {
                    apiClient.fetchSearchItems(value).then((searchItemResults) {
                      context
                          .read<SearchData>()
                          .updateSearchResults(searchItemResults);
                    }).catchError((error) {
                      searchData.updateNotFound();
                      _logger.e('(catalog)fetchCategories error $error');
                    });
                  } else {
                    context
                        .read<SearchData>()
                        .updateSearchResults([]); // Clear search items
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Search Groceries',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
