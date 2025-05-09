import 'dart:async';
import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:pronto/home/address/address_screen.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/catalog_screen.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/home/api_client_home.dart';
import 'package:pronto/home/components/network_utility.dart';
import 'package:pronto/home/models/place_auto_complete_response.dart';
import 'package:pronto/home/models/prediction_auto_complete.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/utils/globals.dart';
import 'package:provider/provider.dart';
import 'package:pronto/item/category_items/category_items_screen.dart';

class SkipHomePage extends StatefulWidget {
  const SkipHomePage({super.key, required this.title});
  static const String routeName = '/myHomePage';

  final String title;

  @override
  State<SkipHomePage> createState() => _SkipHomePageState();
}

class _SkipHomePageState extends State<SkipHomePage>
    with SingleTickerProviderStateMixin {
  final HomeApiClient apiClient = HomeApiClient('https://localhost:3000');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Category> categories = [];
  List<Category> promotions = [];
  List<Address> addresses = [];
  Address? defaultAddress;

  late AnimationController _buttonController;

  bool isLoggedIn = false;
  bool isAddress = false;
  bool showDialogVisible = false;
  bool isLoadingGetAddress = true;

  String customerId = "0";
  String phone = "0";
  String cartId = "0";
  String streetAddress = "";
  int addressId = 0;
  int? selectedAddressIndex;
  int currentIndex = 0;
  final Logger _logger = Logger();
  final storage = const FlutterSecureStorage();

  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    print("Show Address: $showAddress");

    fetchCategories();
    fetchPromotions();
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await apiClient.fetchCategories();
      setState(() {
        categories = fetchedCategories;
        isLoading = false;
      });
    } catch (err) {
      _logger.e('(home)fetchCategories error $err');
    }
  }

  Future<void> fetchPromotions() async {
    try {
      final fetchedPromotions = await apiClient.fetchPromotions();
      setState(() {
        promotions = fetchedPromotions;
      });
    } catch (err) {
      _logger.e('(home)fetchPromotions error $err');
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
      "key": modApikey,
    });
    String? response = await NetworkUtility.fetchUrl(uri);

    if (response != null) {
      PlaceAutoCompleteResponse result =
          PlaceAutoCompleteResponse.parseAutocompleteResult(response);

      if (result.predictions != null) {
        setState(() {
          placePredictions = result.predictions!;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //print("DeliveryAddress.ID ${cart.deliveryAddress.id}");

    return Scaffold(
      key: _scaffoldKey,
      appBar: const HomeScreenAppBar(),
      body: isLoading
          ? const CircularProgressIndicator()
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _onRefresh,
              child: CustomScrollView(
                // <-- Using CustomScrollView
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Consumer<CartModel>(
                      builder: (context, cart, child) {
                        return Column(
                          children: [
                            // Your other body content
                            Container(
                              padding: const EdgeInsets.all(2),
                              height: 60,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 42, // Flex 7 for the main content
                                    child: Container(
                                      decoration: BoxDecoration(
                                        image: const DecorationImage(
                                          image: AssetImage(
                                              "assets/images/store.png"),
                                          opacity: 0.9,
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                        border: Border.all(
                                            color: Colors.deepPurpleAccent),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromARGB(
                                                255, 248, 219, 253),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Delivery in 10 minutes",
                                          style: GoogleFonts.cantoraOne(
                                              fontSize: 24,
                                              fontStyle: FontStyle.italic,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Highlights(
                                customerId: customerId,
                                phone: phone,
                                promos: promotions), // Pass retrieved values
                            Container(
                              alignment: Alignment
                                  .centerLeft, // Align text to the left
                              padding: const EdgeInsets.only(
                                  left: 16, top: 8.0, bottom: 2.0),
                              child: const Text(
                                'Explore By Categories',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 4,
                      childAspectRatio: 0.64,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return _buildCategoryContainer(
                            context,
                            categories[index].id,
                            categories[index].name,
                            categories[index].image);
                      },
                      childCount: categories.length,
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding:
            const EdgeInsets.only(bottom: 22, top: 10, left: 15, right: 15),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(8), // Squarish border
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to Home
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyPhone()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Squarish shape
                ),
              ),
              child: const Text('Home'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Cart
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyPhone()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white, // Different background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Squarish shape
                ),
              ),
              child: const Text('Cart'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContainer(
      BuildContext context, int categoryID, String categoryName, String image) {
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
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.10,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      spreadRadius: 0,
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext context, Object exception,
                      StackTrace? stackTrace) {
                    return Container(
                      height: 120,
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
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.06,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    categoryName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        height: 1.3,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black), // Adjusting the line spacing here
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }
}

class Highlights extends StatelessWidget {
  const Highlights({
    required this.customerId,
    required this.phone,
    required this.promos,
    super.key,
  });

  final String customerId;
  final String phone;
  final List<Category> promos;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        CarouselSlider(
          items: promos.map((promo) {
            // Use promos list here
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryItemsPage(
                      categoryID: promo.id,
                      categoryName: promo.name,
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 1,
                shadowColor: Colors.grey,
                color: const Color.fromARGB(255, 230, 88, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SizedBox(
                  width: 300,
                  height: 500,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(20),
                    child: Image.network(promo.image,
                        fit: BoxFit.cover), // Use promo.image here
                  ),
                ),
              ),
            );
          }).toList(),

          // Slider Container properties
          options: CarouselOptions(
            height: 125.0,
            enlargeCenterPage: false,
            autoPlay: true,
            aspectRatio: 7 / 9,
            autoPlayCurve: Curves.fastOutSlowIn,
            autoPlayInterval: const Duration(seconds: 4),
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.95,
          ),
        ),
      ],
    );
  }
}

class HomeScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title; // Make the title parameter optional
  //final _MyHomePageState homePageState; // Add this line

  const HomeScreenAppBar({this.title, super.key});

  Future<void> signOutUser(BuildContext context) async {
    // Clear the data in "customerId" key
    if (ModalRoute.of(context)?.isActive == true) {
      //print("Signing Out User");
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'customerId');
      await storage.delete(key: 'cartId');
      await storage.delete(key: 'phone');
    }
    // ignore: use_build_context_synchronously
    Provider.of<LoginStatusProvider>(context, listen: false)
        .updateLoginStatus(false, null);

    // Perform any additional sign-out logic if needed
    // For example, you might want to navigate to the login screen
  }

  Future<String> initiatePhonePePayment(int cartId) async {
    var headers = {'Content-Type': 'application/json'};
    var request =
        http.Request('POST', Uri.parse('$baseUrl/phonepe-payment-init'));
    // Replace with actual parameters
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = json.decode(responseBody);

        // Correct path to extract the URL
        return decodedResponse['data']['instrumentResponse']['redirectInfo']
            ['url'];
      } else {
        // Handle non-200 responses
        var errorResponse = await response.stream.bytesToString();
        // Log the error response or handle it as per your application's requirement
        print('Error response: $errorResponse');
        return 'Error: Received status code ${response.statusCode}';
      }
    } catch (e) {
      // Handle exceptions
      print('Exception occurred: $e');
      return 'Exception: $e';
    }
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(130); // Increased height to accommodate content

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
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
                  height: 40.0, // Set height of the container
                  width: 40.0, // Set width of the container
                  decoration: const BoxDecoration(
                      // Background color of the container
                      shape: BoxShape.circle,
                      color: Colors.transparent // Circular shape
                      ),
                  child: IconButton(
                      icon: const Icon(Icons.electric_bolt_rounded),
                      color: Colors.transparent, // Icon color
                      onPressed: () {
                        context.push('/setting');
                      }),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.only(left: 0.0),
                  margin: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: TextButton(
                    onPressed: () {
                      //homePageState._openBottomSheet();
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
                        'Otto Mart',
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 40.0, // Set height of the container
                  width: 40.0, // Set width of the container
                  decoration: const BoxDecoration(
                    // Background color of the container
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black45,
                        Colors.black87
                      ], // Gradient colors
                    ), // Circular shape
                  ),
                  child: IconButton(
                      icon: const Icon(Icons.person),
                      color: Colors.white, // Icon color
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyPhone()),
                        );
                      }),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
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
                            builder: (context) => const MyPhone()),
                      );
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyPhone()),
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
        toolbarHeight: 120,
      ),
    );
  }
}
