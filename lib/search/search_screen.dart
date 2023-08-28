import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/item/product.dart';
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

    return Scaffold(
      appBar: CustomAppBar(
          categoryName: 'Pronto', searchFocusNode: searchFocusNode),
      body: const SearchItemList(),
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
                      viewportFraction: 1.0),
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
                ? Text('no results for $searchQuery')
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
            color: Colors.white, //const Color.fromARGB(255, 212, 187, 255),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 0.0,
                crossAxisSpacing: 0.0,
              ),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return ListItem(
                  name: searchResults[index].name,
                  id: searchResults[index].id,
                  price: searchResults[index].price,
                  stockQuantity: searchResults[index].stockQuantity,
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
  const ListItem(
      {required this.name,
      required this.id,
      required this.price,
      required this.stockQuantity,
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
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color.fromARGB(255, 200, 183, 246)),
          borderRadius: BorderRadius.circular(4.0),
        ),
        margin: index == 0
            ? const EdgeInsets.only(
                top: 2.0,
                left: 6.0,
              )
            : const EdgeInsets.only(top: 2.0, left: 6.0, right: 6.0),
        child: Card(
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(name),
              ),
              const Spacer(), // Space filler to push the Price and Button to the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      price.toString(),
                      style: const TextStyle(fontSize: 16),
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
                            productId: id.toString(),
                            productName: name,
                            price: price,
                            quantity: 1,
                            stockQuantity: stockQuantity);
                        cart.addItemToCart(cartItem);
                      },
                      child: itemIndexInCart != -1
                          ? Container(
                              decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                      255, 140, 98, 255), // Add border
                                  borderRadius: BorderRadius.circular(3.0)),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        context
                                            .read<CartModel>()
                                            .removeItem(itemId: id.toString());
                                      },
                                      child: const Icon(
                                        Icons.horizontal_rule,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      cart.items[itemIndexInCart].quantity
                                          .toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        cart.addItemToCart(CartItem(
                                            productId: id.toString(),
                                            productName: name,
                                            price: price,
                                            stockQuantity: stockQuantity));
                                      },
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          : const Text(
                              'Add +',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String categoryName;
  final FocusNode searchFocusNode;

  const CustomAppBar(
      {required this.categoryName, required this.searchFocusNode, Key? key})
      : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final SearchItemApiClient apiClient =
      SearchItemApiClient('https://localhost:3000');

  List<Item> resultSearchItems = [];

  Future<void> fetchSearchItems(String queryString) async {
    try {
      final fetchedSearchItems = await apiClient.fetchSearchItems(queryString);
      setState(() {
        resultSearchItems = fetchedSearchItems;
        print(resultSearchItems[1].name);
      });
    } catch (err) {
      print('(catalog)fetchCategories error $err');
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
        padding: const EdgeInsets.only(top: 15),
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
                      print('(catalog)fetchCategories error $error');
                      searchData.updateNotFound();
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
