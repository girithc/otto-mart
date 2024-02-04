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
    print("Show Address: $showAddress");

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

    CartModel cartModel = CartModel(storedCustomerId!);
    Address? deliveryAddress = cartModel.deliveryAddress;

    setState(() {
      customerId = storedCustomerId;
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
    // Your HTTP request logic here
    var headers = {
      'Content-Type': 'application/json',
      'Cookie': 'token=your_token'
    };
    var request = http.Request('POST', Uri.parse('$baseUrl/address'));
    String? storedCustomerId = await storage.read(key: 'customerId');

    final Map<String, dynamic> body = {
      "customer_id": int.parse(storedCustomerId!),
      "is_default": true // Replace with the actual customer_id value
    };
    request.headers.addAll(headers);

    // Send the HTTP POST request
    //final http.Response response = await http.post(Uri.parse("$baseUrl/address"),headers: headers,body: jsonEncode(body),);

    final response =
        await network.postWithAuth('/address', additionalData: body);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Address> items =
          jsonData.map((item) => Address.fromJson(item)).toList();
      setState(() {
        isLoading = false;
        print("Address Fetched ${items[0]}");
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

    // Update the state to indicate loading is complete
  }

  @override
  Widget build(BuildContext context) {
    //var cart = context.watch<CartModel>();
    //print("DeliveryAddress.ID ${cart.deliveryAddress.id}");
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
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(2),
                                height: 60,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 20, // Flex 3 for the address
                                      child: GestureDetector(
                                        onTap: () {
                                          context.go('/select-address');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 0),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            border: Border.all(
                                                color: Colors.deepPurpleAccent,
                                                width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.shade300,
                                                spreadRadius: 2,
                                                blurRadius: 3,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ), // No background color for the first child
                                          child: Center(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .location_on, // Location marker icon
                                                  color:
                                                      Colors.deepPurpleAccent,
                                                  size: 20,
                                                ),
                                                const SizedBox(
                                                    width:
                                                        8), // Provides a gap between the icon and the text
                                                Expanded(
                                                  // Makes the text widget flexible
                                                  child: Text(
                                                    cart.deliveryAddress
                                                        .streetAddress,
                                                    style:
                                                        GoogleFonts.cantoraOne(
                                                            fontSize: 18,
                                                            fontStyle: FontStyle
                                                                .normal,
                                                            color:
                                                                Colors.black),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines:
                                                        1, // Ensures the text does not wrap to more than one line
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(),
                                    ),
                                    Expanded(
                                      flex: 42, // Flex 42 for the main content
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            left: 5.0, top: 10, bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.shade300,
                                              spreadRadius: 2,
                                              blurRadius: 3,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          // Align content to the start of the Row
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Spacing between icon and text
                                            Text(
                                              "Free delivery @ 149",
                                              style: GoogleFonts.cantoraOne(
                                                  fontSize: 24,
                                                  fontStyle: FontStyle.normal,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black),
                                              maxLines:
                                                  1, // Ensures the text does not wrap to more than one line
                                              // Add ellipsis when text overflows
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

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
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.015,
            top: 0,
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
      const Size.fromHeight(130); // Increased height to accommodate content

  @override
  Widget build(BuildContext context) {
    //var cart = context.watch<CartModel>();
    return GestureDetector(
      // GestureDetector captures taps on the screen
      onTap: () {
        // When a tap is detected, reset the focus
        FocusScope.of(context).unfocus();
      },
      child: AppBar(
        surfaceTintColor: Colors.white,
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
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.deepPurpleAccent,
                        Colors.purpleAccent
                      ], // Gradient colors
                    ), // Circular shape
                  ),
                  child: IconButton(
                      icon: const Icon(Icons.person),
                      color: Colors.white, // Icon color
                      onPressed: () {
                        context.push('/setting');
                      }),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  "Delivery in $randomNumber minutes",
                  style: GoogleFonts.cantoraOne(
                      fontSize: 24,
                      fontStyle: FontStyle.normal,
                      color: Colors.black),
                  maxLines:
                      1, // Ensures the text does not wrap to more than one line
                  // Add ellipsis when text overflows
                ),
                Image.asset(
                  "assets/images/scooter.jpg", // Path to your scooter image
                  height: 50, // Set an appropriate height for the icon
                ),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.deepPurpleAccent,
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 2),
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
        toolbarHeight: 120,
      ),
    );
  }
}
