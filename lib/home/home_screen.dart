import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:pronto/cart/order/confirmed_order_screen.dart';
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
  final network = NetworkService();
  String? orderStatus;
  int? orderId;

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
  bool storeOpen = true;
  String storeOpenTime = '';
  int currentIndex = 0;
  final Logger _logger = Logger();
  final storage = const FlutterSecureStorage();
  List<Order> orders = [];
  int selectedOrder = 0;

  //bool isLoading = true;
  @override
  void initState() {
    super.initState();
    //print("Show Address: $showAddress");

    fetchCategories();
    fetchPromotions();
    checkForPlacedOrder();
    retrieveCustomerInfo();
    cartInit();
    getStoreAddress();
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

  Future<void> cartInit() async {
    final cart = context.read<CartModel>();
    cart.addItemToCart(CartItem(
        productId: '1',
        productName: '1',
        price: 0,
        soldPrice: 0,
        quantity: 0,
        stockQuantity: 0,
        image: ''));
  }

  Future<void> getStoreAddress() async {
    //print("Entered Get Store Address");
    final storeId = await storage.read(key: 'storeId');
    final addressId = await storage.read(key: 'addressId');
    final networkService = NetworkService();
    Map<String, dynamic> body = {
      "store_id": int.parse(storeId!),
      "address_id": int.parse(addressId!)
    };
    final response = await networkService.postWithAuth('/store-address',
        additionalData: body);

    //print("Response Store Address ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        streetAddress = data['address'];
        storeOpen = data['store_open'];
        if (!storeOpen) {
          DateTime parsedStoreOpenTime = DateTime.parse(data['opening_time']);

          // Add 5 hours and 30 minutes to the parsed time
          DateTime adjustedStoreOpenTime =
              parsedStoreOpenTime.add(const Duration(hours: 5, minutes: 30));

          // Format the adjusted time part into a verbal format like "9:00 AM"
          storeOpenTime = DateFormat('h:mm a').format(adjustedStoreOpenTime);
        }
      });
    } else {}
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

  Future<void> checkForPlacedOrder() async {
    //print("Enter Check For Placed Order");
    final phone = await storage.read(key: 'phone');
    final response = await network.postWithAuth('/check-for-placed-order',
        additionalData: {"phone": phone});

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);

      setState(() {
        orders =
            jsonResponse.map((orderJson) => Order.fromJson(orderJson)).toList();
        if (orders.isNotEmpty) {
          selectedOrder = 1;
        }
      });
    } else {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: RefreshIndicator(
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
                        GestureDetector(
                          // GestureDetector captures taps on the screen
                          onTap: () {
                            // When a tap is detected, reset the focus
                            FocusScope.of(context).unfocus();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: storeOpen
                                  ? const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        // Top color of the gradient
                                        Colors.white10,
                                        Colors
                                            .white, // Bottom color of the gradient
                                      ],
                                    )
                                  : LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.redAccent.withOpacity(0.5),
                                        Colors.redAccent.withOpacity(0.2),
                                        Colors.grey.shade100.withOpacity(
                                            0.1), // Top color of the gradient
                                        Colors
                                            .white, // Bottom color of the gradient
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
                                      Consumer<CartModel>(
                                        // Wrap the Expanded widget with Consumer<CartModel>
                                        builder: (context, cart, child) {
                                          return Expanded(
                                            child: GestureDetector(
                                              onTap: () =>
                                                  context.go('/select-address'),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .center, // Center the column in the expanded space
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start, // Center the text horizontally
                                                children: [
                                                  SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.001),
                                                  !storeOpen
                                                      ? Text(
                                                          "Closed. Will Open @ $storeOpenTime",
                                                          style: const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        )
                                                      : RichText(
                                                          text: TextSpan(
                                                            children: <InlineSpan>[
                                                              WidgetSpan(
                                                                child: Icon(
                                                                  Icons
                                                                      .near_me_rounded, // Choose the icon you want to use
                                                                  color: Colors
                                                                      .deepPurpleAccent
                                                                      .shade400,
                                                                  size:
                                                                      24, // Adjust the size of the icon
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    ' Home', // Part of the text you want to style differently
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .deepPurpleAccent
                                                                      .shade400,
                                                                  fontSize:
                                                                      22, // Different color for this part
                                                                  // You can add more styles here if needed
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                  SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.006),
                                                  GestureDetector(
                                                    onTap: () => context.go(
                                                        '/select-address'), // Navigate to the settings page on tap
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize
                                                          .min, // Use the minimum space needed by the children
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center, // Center the row contents
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            "${cart.deliveryAddress.streetAddress}, ${cart.deliveryAddress.lineOne}, ${cart.deliveryAddress.lineTwo}", //streetAddress, // Placeholder for the second line of text
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                const TextStyle(
                                                              fontSize:
                                                                  14, // Adjust the font size as needed
                                                              color:
                                                                  Colors.black,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      GestureDetector(
                                        onTap: () => context.go('/setting'),
                                        child: Container(
                                          alignment: Alignment.topLeft,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.07, // Set height of the container
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.07, // Set width of the container
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.deepPurpleAccent.shade400
                                                    .withOpacity(0.25),
                                                Colors.deepPurpleAccent.shade400
                                                    .withOpacity(0.65)
                                              ], // Gradient colors
                                            ), // Circular shape
                                          ),
                                          child: Center(
                                            child: ClipOval(
                                              child: Image.asset(
                                                "assets/icon/icon.jpeg",
                                                fit: BoxFit.cover,
                                                // Adjust width if needed
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.015,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10.0),
                                      border: Border.all(
                                          color: Colors.grey.shade500),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 0.0),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 0.0),
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
                                                    builder: (context) =>
                                                        const SearchTopLevel()),
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
                                                  hintText:
                                                      'Search For Groceries',
                                                  hintStyle: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54,
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
                              toolbarHeight:
                                  MediaQuery.of(context).size.height * 0.16,
                            ),
                          ),
                        ),

                        promotions.isNotEmpty
                            ? Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Promotions(
                                    customerId: customerId,
                                    phone: phone,
                                    promos: promotions),
                              )
                            : Container(height: 40), // Pass retrieved values
/*
                        promotions.isNotEmpty
                            ? Container(
                                child: BrandPromotions(
                                    customerId: customerId,
                                    phone: phone,
                                    promos: promotions),
                              )
                            : Container(height: 40), // Pass retrieved values
*/
                        Container(
                          color: Colors.white,
                          alignment:
                              Alignment.centerLeft, // Align text to the left
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

                        Container(),
                        const SizedBox(
                          height: 10,
                        )
                      ],
                    );
                  },
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.625,
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
        height: orders.isNotEmpty
            ? MediaQuery.of(context).size.height * 0.14
            : MediaQuery.of(context).size.height * 0.08,
        padding: const EdgeInsets.only(left: 5, right: 5),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            orders.isNotEmpty
                ? // Use Dart's collection-if to include a widget conditionally
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height *
                            0.06, // Set a fixed height for the ListView
                        color: Colors.white,
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                // Navigate to Cart
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderConfirmed(
                                      newOrder: false,
                                      orderId: orders[index].cartId,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            0.15),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(0),
                                height:
                                    MediaQuery.of(context).size.height * 0.04,
                                width: MediaQuery.of(context).size.width * 0.6,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Circular avatar-like container
                                    Container(
                                      alignment: Alignment.topCenter,
                                      padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                          bottom: 10,
                                          top: 8),
                                      height: 40, // Diameter of the circle
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurpleAccent
                                            .shade400, // White background color
                                        shape: BoxShape
                                            .circle, // Makes the container circular
                                      ),
                                      child: Text(
                                        (index + 1)
                                            .toString(), // Convert int to String
                                        // Example text, replace with what you need
                                        style: const TextStyle(
                                          color: Colors.white, // Text color
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              18, // Adjust the size as needed
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                        width:
                                            10), // Spacing between the circle and text
                                    // Text
                                    Text(
                                      'Order ${orders[index].status}',
                                      style: TextStyle(
                                        color: Colors.deepPurpleAccent.shade400,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : Container(),
            Row(
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
                      Icon(Icons.refresh_outlined,
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
                        Icons.search,
                        size: 15,
                        color: Colors.black87,
                      ), // Icon for Cart
                      SizedBox(width: 4),
                      Text('Search',
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
                        Icons.shopping_bag_outlined,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContainer(BuildContext context, int index,
      int categoryID, String categoryName, String image) {
    // Determine the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Set a threshold for what you consider a 'small' screen, like the iPhone SE
    double smallScreenWidth = 320.0;

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
        padding: const EdgeInsets.only(left: 0, right: 0, bottom: 1),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0), color: Colors.white),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.12,
              margin: const EdgeInsets.only(left: 3, right: 3, top: 3),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 230, 231, 238).withOpacity(
                    0.45), // Color.fromARGB(255, 242, 219, 255).withOpacity(0.5),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.white),
                boxShadow: const [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                    20.0), // Match the container's border radius
                child: image.contains('.avif')
                    ? AvifImage.network(
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
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      )
                    : Image.network(
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
                                'coming\nsoon',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.005,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
              child: Align(
                alignment: Alignment.center,
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
        const SizedBox(
          height: 15,
        ),
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
                shadowColor: Colors.deepPurpleAccent.withOpacity(0.8),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.3,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(0),
                  child: Image.network(promo.image,
                      fit: BoxFit.fill), // Use promo.image here
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
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }
}

class HomeScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int randomNumber; // Make the title parameter optional
  final String streetAddress;
  final bool storeOpen;
  final String storeOpenTime;
  //final _MyHomePageState homePageState; // Add this line

  const HomeScreenAppBar(
      {required this.randomNumber,
      required this.streetAddress,
      required this.storeOpen,
      required this.storeOpenTime,
      super.key});

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
        //print('Error response: $errorResponse');
        return 'Error: Received status code ${response.statusCode}';
      }
    } catch (e) {
      // Handle exceptions
      //print('Exception occurred: $e');
      return 'Exception: $e';
    }
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(140); // Increased height to accommodate content

  @override
  Widget build(BuildContext context) {
    // Assuming storeOpenTime is in a full date-time format like "2023-03-20 09:00:00"

    //var cart = context.watch<CartModel>();
    return GestureDetector(
      // GestureDetector captures taps on the screen
      onTap: () {
        // When a tap is detected, reset the focus
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: storeOpen
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // Top color of the gradient
                    Colors.white10,
                    Colors.white, // Bottom color of the gradient
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.redAccent.withOpacity(0.5),
                    Colors.redAccent.withOpacity(0.2),
                    Colors.grey.shade100
                        .withOpacity(0.1), // Top color of the gradient
                    Colors.white, // Bottom color of the gradient
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
                            Colors.black.withOpacity(0.25),
                            Colors.black.withOpacity(0.65)
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
                                    MediaQuery.of(context).size.height * 0.001),
                            !storeOpen
                                ? Text(
                                    "Closed. Will Open @ $storeOpenTime",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  )
                                : RichText(
                                    textAlign:
                                        TextAlign.center, // Center the text
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize:
                                            21, // Base font size for the whole text
                                        fontWeight: FontWeight.bold,
                                        color: Colors
                                            .black, // Base color for the whole text
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text:
                                              'Morning', // Part of the text you want to style differently
                                          style: TextStyle(
                                              color: Colors.deepPurpleAccent,
                                              fontSize: 24
                                              // Different color for this part
                                              // You can add more styles here if needed
                                              ),
                                        ),
                                        TextSpan(
                                          text: ' Delivery',
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22
                                              // Different color for this part
                                              // You can add more styles here if needed
                                              ), // First part of the text
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
                                      "${cart.deliveryAddress.streetAddress}, ${cart.deliveryAddress.lineOne}, ${cart.deliveryAddress.lineTwo}", //streetAddress, // Placeholder for the second line of text
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize:
                                            18, // Adjust the font size as needed
                                        color: Colors.black,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  const Icon(
                                    Icons.directions_bike_outlined,
                                    size: 20, // Downward caret icon
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
                    height: 15.0, // Set height of the container
                    width: 30.0, // Set width of the container
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.transparent),
                    child: IconButton(
                        icon: const Icon(
                          Icons.person,
                          size: 14,
                        ),
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
                  border: Border.all(color: Colors.grey.shade500),
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
                                color: Colors.black54,
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

class Order {
  final int cartId;
  final String status;

  Order({required this.cartId, required this.status});

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      cartId: json['cart_id'],
      status: json['status'],
    );
  }
}

class Promotions extends StatelessWidget {
  const Promotions({
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.16,
      child: Container(
        margin: const EdgeInsets.all(5),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: promos.map((promo) {
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
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: buildCard(context, promo),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildCard(BuildContext context, Category promo) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.32,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: Colors.deepPurpleAccent.shade400,
          borderRadius: BorderRadius.circular(20.0)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            promo.name,
            style: const TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}

class BrandPromotions extends StatelessWidget {
  const BrandPromotions({
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.16,
      child: Container(
        margin: const EdgeInsets.all(5),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: promos.map((promo) {
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
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: buildCard(context, promo),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildCard(BuildContext context, Category promo) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.32,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.0)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            promo.name,
            style: const TextStyle(
                fontSize: 24,
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}
