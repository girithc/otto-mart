import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
import 'package:pronto/utils/constants.dart';
import 'package:pronto/home/api_client_home.dart';
import 'package:pronto/home/components/network_utility.dart';
import 'package:pronto/home/models/place_auto_complete_response.dart';
import 'package:pronto/home/models/prediction_auto_complete.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/search/search_screen.dart';
import 'package:pronto/utils/globals.dart';
import 'package:pronto/utils/network/service.dart';
import 'package:provider/provider.dart';
import 'package:pronto/item/category_items/category_items_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  static const String routeName = '/myHomePage';

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final HomeApiClient apiClient = HomeApiClient('https://localhost:3000');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Category> categories = [];
  List<Category> promotions = [];
  List<Address> addresses = [];
  Address? defaultAddress;

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
    //print("Show Address: $showAddress");

    fetchCategories();
    fetchPromotions();

    _checkAddressAndLoginStatus();
    retrieveCustomerInfo();
  }

  Future<void> retrieveCustomerInfo() async {
    String? storedCustomerId = await storage.read(key: 'customerId');
    String? storedPhone = await storage.read(key: 'phone');
    String? storedCartId =
        await storage.read(key: 'cartId'); // Get cartId from secure storage

    setState(() {
      customerId = storedCustomerId!;
      phone = storedPhone ?? "0";
      cartId = storedCartId ?? "0"; // Set the cartId
      //addressId = deliveryAddress.id;
      isLoggedIn = customerId.isNotEmpty && customerId != "0";
    });

    //print("AddressId: $addressId");
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await apiClient.fetchCategories();
      setState(() {
        categories = fetchedCategories;
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
        //print("Promotions: ${promotions[0].image}");
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

  Future<String?> getOrderStatus() async {
    return await storage.read(key: 'orderStatus');
  }

  Future<void> deleteOrderStatus() async {
    await storage.delete(key: 'orderStatus');
    setState(() {}); // Trigger a rebuild if your widget is stateful
  }

  Future<void> _checkAddressAndLoginStatus() async {
    final network = NetworkService();
    var headers = {
      'Content-Type': 'application/json',
      'Cookie': 'token=your_token'
    };
    var request = http.Request('POST', Uri.parse('$baseUrl/address'));
    String? storedCustomerId = await storage.read(key: 'customerId');

    final Map<String, dynamic> body = {
      "customer_id": int.parse(storedCustomerId!),
      "is_default": true
    };
    request.headers.addAll(headers);
    final response =
        await network.postWithAuth('/address', additionalData: body);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Address> items =
          jsonData.map((item) => Address.fromJson(item)).toList();
      setState(() {
        isLoading = false;
        //print("Address Fetched ${items[0]}");
        showDialogVisible = false;
        defaultAddress = items[0];
      });
    } else {
      setState(() {
        isLoading = false;
        showDialogVisible = true;
      });
      print(response.reasonPhrase);
    }
  }

  @override
  Widget build(BuildContext context) {
    int randomNumber = 3 + Random().nextInt(5);

    return Scaffold(
      key: _scaffoldKey,
      appBar: HomeScreenAppBar(
        randomNumber: randomNumber,
      ),
      body: isLoading
          ? const CircularProgressIndicator()
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _onRefresh,
              child: Container(
                color: Colors.white,
                child: CustomScrollView(
                  // <-- Using CustomScrollView
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: Consumer<CartModel>(
                        builder: (context, cart, child) {
                          return Column(
                            children: [
                              // Your other body content

                              promotions.isNotEmpty
                                  ? Highlights(
                                      customerId: customerId,
                                      phone: phone,
                                      promos: promotions)
                                  : Container(
                                      height: 40), // Pass retrieved values
                              Container(
                                color: Colors.white,
                                alignment: Alignment
                                    .centerLeft, // Align text to the left
                                padding: const EdgeInsets.only(
                                    left: 16, top: 8.0, bottom: 4.0),
                                child: const Text(
                                  'Explore By Categories',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
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
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.62,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return _buildCategoryContainer(
                              context,
                              index,
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
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.025,
            top: 5,
            left: 15,
            right: 15),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1),
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
          mainAxisSize: MainAxisSize.max,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to Home
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const MyHomePage(title: 'Otto Mart')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Background color
                surfaceTintColor: Colors.white,
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Squarish shape
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_outlined,
                      size: 15, color: Colors.black87), // Icon for Home
                  SizedBox(width: 4),
                  Text('Home',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Cart
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SearchTopLevel()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Background color
                surfaceTintColor: Colors.white,
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Squarish shape
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.travel_explore_outlined,
                    size: 15,
                    color: Colors.black87,
                  ), // Icon for Cart
                  SizedBox(width: 4),
                  Text('Explore',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Cart
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyCart()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Background color
                surfaceTintColor: Colors.white,
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Squarish shape
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 15,
                    color: Colors.black87,
                  ), // Icon for Cart
                  SizedBox(width: 4),
                  Text('Cart',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContainer(BuildContext context, int index,
      int categoryID, String categoryName, String image) {
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
        margin: (index % 4 == 0)
            ? const EdgeInsets.only(left: 5, right: 2.5, bottom: 1)
            : (index % 4 == 3)
                ? const EdgeInsets.only(left: 2.5, right: 5, bottom: 1)
                : const EdgeInsets.only(left: 2.5, right: 2.5, bottom: 1),
        padding: const EdgeInsets.only(left: 0, right: 0, bottom: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              // Top color of the gradient
              Colors.deepPurpleAccent.shade200.withOpacity(0.25),
              Colors.deepPurpleAccent.shade100
                  .withOpacity(0.1), // Bottom color of the gradient
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.12,
              margin: const EdgeInsets.only(left: 3, right: 3, top: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.white),
                boxShadow: const [],
              ),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return Container(
                    height: 120,
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
              height: MediaQuery.of(context).size.height * 0.04,
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
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
  final int randomNumber; // Make the title parameter optional
  //final _MyHomePageState homePageState; // Add this line

  const HomeScreenAppBar({required this.randomNumber, super.key});

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
      const Size.fromHeight(140); // Increased height to accommodate content

  @override
  Widget build(BuildContext context) {
    //var cart = context.watch<CartModel>();
    return GestureDetector(
      // GestureDetector captures taps on the screen
      onTap: () {
        // When a tap is detected, reset the focus
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurpleAccent.shade100
                  .withOpacity(0.1), // Top color of the gradient
              Colors.deepPurpleAccent.shade200
                  .withOpacity(0.25), // Bottom color of the gradient
            ],
          ),
        ),
        child: AppBar(
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading:
              false, // This line removes the default back button
          backgroundColor: Colors
              .transparent, //Theme.of(context).colorScheme.inversePrimary,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/setting'),
                    child: Container(
                      alignment: Alignment.topLeft,
                      height: 35.0, // Set height of the container
                      width: 35.0, // Set width of the container
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.35)
                          ], // Gradient colors
                        ), // Circular shape
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ),
                  Consumer<CartModel>(
                    // Wrap the Expanded widget with Consumer<CartModel>
                    builder: (context, cart, child) {
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment
                              .center, // Center the column in the expanded space
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Center the text horizontally
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.01),
                            RichText(
                              textAlign: TextAlign.center, // Center the text
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize:
                                      20, // Base font size for the whole text
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .black, // Base color for the whole text
                                ),
                                children: <TextSpan>[
                                  const TextSpan(
                                    text:
                                        'Delivery in ', // First part of the text
                                  ),
                                  TextSpan(
                                    text:
                                        '$randomNumber Mins', // Part of the text you want to style differently
                                    style: const TextStyle(
                                      color: Colors
                                          .deepPurpleAccent, // Different color for this part
                                      // You can add more styles here if needed
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.006),
                            GestureDetector(
                              onTap: () => context.go(
                                  '/select-address'), // Navigate to the settings page on tap
                              child: Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Use the minimum space needed by the children
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Center the row contents
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${cart.deliveryAddress.streetAddress}, ${cart.deliveryAddress.lineOne}", // Placeholder for the second line of text
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize:
                                            16, // Adjust the font size as needed
                                        color: Colors.black,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons
                                        .keyboard_arrow_down, // Downward caret icon
                                    color: Colors.black, // Icon color
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(
                    alignment: Alignment.topRight,
                    height: 20.0, // Set height of the container
                    width: 40.0, // Set width of the container
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.transparent),
                    child: IconButton(
                        icon: const Icon(Icons.person),
                        color: Colors.transparent, // Icon color
                        onPressed: () {}),
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.015,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 0.0),
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                height: MediaQuery.of(context).size.height *
                    0.06, // Increased height to contain the input field
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
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search For Groceries',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
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
          toolbarHeight: MediaQuery.of(context).size.height * 0.16,
        ),
      ),
    );
  }
}
