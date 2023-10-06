import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/item/product.dart';
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

class SearchPage extends StatelessWidget {
  final FocusNode searchFocusNode;

  const SearchPage({required this.searchFocusNode, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Focus the text field when the page is loaded
    searchFocusNode.requestFocus();
    final searchData = context.watch<SearchData>();
    final searchQuery = searchData.searchQuery;

    return Scaffold(
      appBar: CustomAppBar(
          categoryName: 'Pronto', searchFocusNode: searchFocusNode),
      body: searchQuery.length > 2
          ? const SearchItemList()
          : const SearchTemplate(),
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
                                  color: Colors.pinkAccent,
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Colors.white, Color.fromARGB(255, 248, 219, 253)],
              ),
            ), //const Color.fromARGB(255, 212, 187, 255),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 0.0,
                crossAxisSpacing: 0.0,
                childAspectRatio: 0.84,
              ),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return ListItem(
                  name: searchResults[index].name,
                  id: searchResults[index].id,
                  price: searchResults[index].price,
                  stockQuantity: searchResults[index].stockQuantity,
                  image: searchResults[index].image,
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
  final int price;
  final int stockQuantity;
  final int index;
  final String image;
  const ListItem(
      {required this.name,
      required this.id,
      required this.price,
      required this.stockQuantity,
      required this.image,
      required this.index,
      super.key});

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>(); // Access the CartModel instance
    var itemIndexInCart =
        cart.items.indexWhere((item) => item.productId == id.toString());
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Product(
              productName: name,
              productId: id,
              price: price,
              stockQuantity: stockQuantity,
              image: image,
            ),
          ),
        );
      },
      child: Material(
        elevation: 4.0,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: borderColor, width: 1.0),
                borderRadius: BorderRadius.circular(3.0),
              ),
              margin: index == 0
                  ? const EdgeInsets.only(
                      top: 4.0,
                      left: 6.0,
                    )
                  : const EdgeInsets.only(top: 4.0, left: 4.0, right: 6.0),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                    child: Center(
                      child: Image.network(
                        image,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      margin: const EdgeInsets.only(top: 2.0),
                      alignment: Alignment.centerLeft,
                      height: 28,
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
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 0.9,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      margin: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      height: 17,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.0),
                        border: Border.all(color: borderColor),
                      ),
                      child: const Text(
                        '100g',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                        height: 17,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(1.0),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_offer_outlined,
                              color: Colors.deepPurple,
                              size: 15,
                            ),
                            const SizedBox(
                                width:
                                    5), // Adding some spacing between icon and text
                            Text(
                              'Add 1, Unlock offer',
                              maxLines: 2,
                              style: GoogleFonts.firaSans(
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  color: Colors.deepPurple,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        )),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      height: 37,
                      margin: const EdgeInsets.only(top: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.0),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\u{20B9}$price',
                          ),
                          itemIndexInCart != -1
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 2),
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 140, 98, 255), // Add border
                                      borderRadius: BorderRadius.circular(3.0)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          context.read<CartModel>().removeItem(
                                              itemId: id.toString());
                                        },
                                        child: const Icon(
                                          Icons.horizontal_rule,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        cart.items[itemIndexInCart].quantity
                                            .toString(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          cart.addItemToCart(CartItem(
                                              productId: id.toString(),
                                              productName: name,
                                              price: price,
                                              quantity: 1,
                                              stockQuantity: stockQuantity,
                                              image: image));
                                        },
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.zero,
                                  margin: const EdgeInsets.only(
                                      right: 2, top: 2, bottom: 4),
                                  child: ElevatedButton(
                                      onPressed: () {
                                        final cartItem = CartItem(
                                            productId: id.toString(),
                                            productName: name,
                                            price: price,
                                            quantity: 1,
                                            stockQuantity: stockQuantity,
                                            image: image);
                                        cart.addItemToCart(cartItem);
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          padding: const EdgeInsets.all(0),
                                          side: const BorderSide(
                                            width: 1.0,
                                            color: Colors.pinkAccent,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          )),
                                      child: const Text(
                                        'Add+',
                                        style: TextStyle(
                                            color: Colors.pinkAccent,
                                            fontSize: 12),
                                      )),
                                )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10, // Adjust the position as needed
              left: 10, // Adjust the position as needed
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  '5% OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
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
  Size get preferredSize => const Size.fromHeight(65);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final SearchItemApiClient apiClient =
      SearchItemApiClient('https://localhost:3000');
  final Logger _logger = Logger();

  List<Item> resultSearchItems = [];

  Future<void> fetchSearchItems(String queryString) async {
    try {
      if (queryString.length > 2) {
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
        padding: const EdgeInsets.only(
          top: 35,
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
                  if (value.length > 2) {
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