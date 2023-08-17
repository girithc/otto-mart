import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pronto/address/address_screen.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/catalog_screen.dart';
import 'package:pronto/constants.dart';
import 'package:pronto/deprecated/cart.dart';
import 'package:pronto/home/api_client_home.dart';
import 'package:pronto/home/components/horizontal_scroll_items.dart';
import 'package:pronto/home/components/network_utility.dart';
import 'package:pronto/home/models/place_auto_complete_response.dart';
import 'package:pronto/home/models/prediction_auto_complete.dart';
import 'package:pronto/login/login_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final HomeApiClient apiClient = HomeApiClient('https://localhost:3000');
  List<Category> categories = [];
  bool _isBottomSheetOpen = false;
  bool _isBottomSheetAddressOpen = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    Future.delayed(Duration.zero, () {
      _openBottomSheet();
    });
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await apiClient.fetchCategories();
      setState(() {
        categories = fetchedCategories;
      });
    } catch (err) {
      print('(home)fetchCategories error $err');
    }
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      // Update the data
    });
  }

  List<PredictionAutoComplete> placePredictions = [];

  void placeAutocomplete(String query) async {
    Uri uri =
        Uri.https("maps.googleapis.com", "maps/api/place/autocomplete/json", {
      "input": query,
      "key": apiKey,
    });
    String? response = await NetworkUtility.fetchUrl(uri);

    if (response != null) {
      PlaceAutoCompleteResponse result =
          PlaceAutoCompleteResponse.parseAutocompleteResult(response);
      String? predictions = result.predictions?[0].description;

      if (result.predictions != null) {
        setState(() {
          placePredictions = result.predictions!;
        });
      }
    }
  }

  void _openBottomSheet() {
    if (!_isBottomSheetOpen) {
      setState(() {
        _isBottomSheetOpen = true;
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return LoginScreen(postLogin: () {
            _openAddressBottomSheet();
          }); // Replace with your actual login screen widget
        },
      ).whenComplete(
        () => setState(() {
          _isBottomSheetOpen = false;
        }),
      );
    }
  }

  void _openAddressBottomSheet() {
    Navigator.of(context).pop();
    if (!_isBottomSheetAddressOpen) {
      setState(() {
        _isBottomSheetAddressOpen = true;
      });
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return const AddressScreen();
        },
      ).whenComplete(
        () => setState(() {
          _isBottomSheetAddressOpen = false;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        homePageState: this, // Pass the reference to the state instance
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Your other body content goes here
              Container(
                //color: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.all(8),
                height: 80,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/store.png"),
                    opacity: 0.9,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Delivery in 10 minutes',
                    style: GoogleFonts.cantoraOne(
                        fontSize: 25,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft, // Align text to the left
                padding: const EdgeInsets.all(16.0),
                child: const Text(
                  'Explore By Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 400,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: categories.length, // Number of grid items
                    itemBuilder: (context, index) {
                      return _buildCategoryContainer(context,
                          categories[index].id, categories[index].name);
                    },
                  ),
                ),
              ),
              const HorizontalScrollItems(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContainer(
      BuildContext context, int categoryID, String categoryName) {
    return GestureDetector(
      onTap: () => {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MyCatalog(categoryID: categoryID, categoryName: categoryName),
          ),
        )
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        color: const Color.fromARGB(255, 248, 219, 253),
        child: Text(
          categoryName,
          style: GoogleFonts.cantoraOne(
            fontSize: 13,
            fontStyle: FontStyle.normal,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title; // Make the title parameter optional
  final _MyHomePageState homePageState; // Add this line

  const CustomAppBar({this.title, required this.homePageState, super.key});

  @override
  Size get preferredSize =>
      const Size.fromHeight(130); // Increased height to accommodate content

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // GestureDetector captures taps on the screen
      onTap: () {
        // When a tap is detected, reset the focus
        FocusScope.of(context).unfocus();
      },
      child: AppBar(
        elevation: 0,
        automaticallyImplyLeading:
            false, // This line removes the default back button
        backgroundColor:
            Colors.white, //Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 5.0),
                  margin: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: TextButton(
                      onPressed: () {
                        homePageState._openBottomSheet();

                        /*
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()));
                      */
                      },
                      child: ShaderMask(
                        shaderCallback: (bounds) => const RadialGradient(
                                center: Alignment.topLeft,
                                radius: 1.0,
                                colors: [
                                  Colors.deepPurple,
                                  Colors.deepPurpleAccent
                                ],
                                tileMode: TileMode.mirror)
                            .createShader(bounds),
                        child: const Text(
                          'Pronto',
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      )),
                ),
                const Spacer(),
                IconButton(
                  padding: const EdgeInsets.only(right: 15.0),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyCart()));
                  },
                ),
                IconButton(
                  padding: const EdgeInsets.only(right: 15.0),
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CartPage()));
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
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
                      child: TextField(
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search For Groceries',
                          border: InputBorder.none,
                        ),
                        onChanged: (text) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        toolbarHeight: 120,
      ),
    );
  }
}
