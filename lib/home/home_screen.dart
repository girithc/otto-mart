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
import 'package:pronto/utils/constants.dart';
import 'package:pronto/home/api_client_home.dart';
import 'package:pronto/home/components/network_utility.dart';
import 'package:pronto/home/models/place_auto_complete_response.dart';
import 'package:pronto/home/models/prediction_auto_complete.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/search/search_screen.dart';
import 'package:pronto/utils/globals.dart';
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
  final bool _bottomSheetShown = false;
  static const String routeName = '/myHomePage';
  List<Category> categories = [];
  List<Category> promotions = [];
  List<Address> addresses = [];
  Address? defaultAddress;

  late AnimationController _buttonController;
  late Animation<Color?> _colorAnim;

  bool isLoggedIn = false;
  bool isAddress = false;
  bool _isMounted = false;
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

  Future<void> getAllAddresses() async {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    final Map<String, dynamic> body = {
      "customer_id":
          int.parse(customerId) // Replace with the actual customer_id value
    };

    // Send the HTTP POST request
    final http.Response response = await http.post(
      Uri.parse("$baseUrl/address"),
      headers: headers,
      body: jsonEncode(body), // Convert the Map to a JSON string
    );

    // Check the response
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty && response.contentLength! > 3) {
        //print("address Response Not Empty ${response.contentLength}");
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Address> items =
            jsonData.map((item) => Address.fromJson(item)).toList();
        setState(() {
          print("Success $addresses");
          addresses = items;
          isLoadingGetAddress = false;
        });
      } else {
        setState(() {
          // print("Empty Response");
          isLoadingGetAddress = false;
        });
        print("Error: ${response.reasonPhrase}");
      }
    }
  }

  Future<Address?> setDefaultAddress(int addressId) async {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    final Map<String, dynamic> body = {
      "customer_id": int.parse(customerId),
      "address_id": addressId,
      "is_default": true
    };

    try {
      final http.Response response = await http.post(
        Uri.parse("$baseUrl/address"),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final decodedResponse = json.decode(response.body);
          if (decodedResponse is Map) {
            // Explicitly cast the response to Map<String, dynamic>
            return Address.fromJson(Map<String, dynamic>.from(decodedResponse));
          } else if (decodedResponse is List) {
            // Handle the case where the response is a List
            final List<Address> items = (decodedResponse)
                .map(
                    (item) => Address.fromJson(Map<String, dynamic>.from(item)))
                .toList();
            return items.isNotEmpty ? items[0] : null;
          }
        }
      } else {
        print("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Exception occurred: $e");
    }
    return null;
  }

  Future<String?> getOrderStatus() async {
    return await storage.read(key: 'orderStatus');
  }

  Future<void> deleteOrderStatus() async {
    await storage.delete(key: 'orderStatus');
    setState(() {}); // Trigger a rebuild if your widget is stateful
  }

  Future<void> _checkAddressAndLoginStatus() async {
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
    final http.Response response = await http.post(
      Uri.parse("$baseUrl/address"),
      headers: headers,
      body: jsonEncode(body), // Convert the Map to a JSON string
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Address> items =
          jsonData.map((item) => Address.fromJson(item)).toList();
      //print("Address: $jsonData");
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

  Future<void> getDefaultAddress() async {}

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
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
                                    flex: 15, // Flex 3 for the address
                                    child: GestureDetector(
                                      onTap: () {
                                        // Reset selectedAddressIndex before opening the bottom sheet
                                        selectedAddressIndex = null;

                                        getAllAddresses().then((_) {
                                          // When getAllAddresses completes execution
                                          showModalBottomSheet(
                                            context: context,
                                            isDismissible:
                                                true, // Prevent dismissing by tapping outside
                                            enableDrag: false,
                                            builder: (BuildContext context) {
                                              return StatefulBuilder(
                                                builder: (BuildContext context,
                                                    StateSetter modalSetState) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.5,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.90,
                                                    decoration:
                                                        const BoxDecoration(
                                                      // other decoration properties like color, border, etc.
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft: Radius.circular(
                                                            10), // Adjust the radius as needed
                                                        topRight: Radius.circular(
                                                            10), // Adjust the radius as needed
                                                      ),
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.80,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 12,
                                                                  horizontal:
                                                                      30),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .white, // Grey background
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10), // Rounded corners
                                                            border: Border.all(
                                                              color: Colors
                                                                  .deepPurpleAccent, // Border color
                                                              width:
                                                                  1.0, // Border width
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.2), // Shadow color
                                                                spreadRadius: 1,
                                                                blurRadius: 5,
                                                                offset: const Offset(
                                                                    0,
                                                                    3), // Changes position of shadow
                                                              ),
                                                            ],
                                                          ),
                                                          child: const Center(
                                                            child: Text(
                                                              "Select Address",
                                                              style: TextStyle(
                                                                  fontSize: 24),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 5),
                                                        Expanded(
                                                          child:
                                                              isLoadingGetAddress
                                                                  ? ListView
                                                                      .builder(
                                                                      itemCount:
                                                                          5, // Display 5 skeleton items for example
                                                                      itemBuilder:
                                                                          (BuildContext context,
                                                                              int index) {
                                                                        return Padding(
                                                                          padding: const EdgeInsets
                                                                              .symmetric(
                                                                              vertical: 10.0,
                                                                              horizontal: 15.0),
                                                                          child:
                                                                              Container(
                                                                            height:
                                                                                20.0, // Height of the skeleton item
                                                                            width:
                                                                                double.infinity,
                                                                            color:
                                                                                Colors.grey[300], // Light grey color for the skeleton
                                                                          ),
                                                                        );
                                                                      },
                                                                    )
                                                                  : ListView
                                                                      .builder(
                                                                      itemCount:
                                                                          addresses.length +
                                                                              2, // Two more than the addresses for the 'add' option and the current address
                                                                      itemBuilder:
                                                                          (BuildContext context,
                                                                              int index) {
                                                                        if (index ==
                                                                            0) {
                                                                          return ListTile(
                                                                            // <-- You missed the return here
                                                                            leading:
                                                                                const Icon(Icons.add), // An add icon
                                                                            title:
                                                                                const Text("Add New Address"),
                                                                            onTap:
                                                                                () {
                                                                              Navigator.of(context).pushReplacement(MaterialPageRoute(
                                                                                builder: (context) => const AddressScreen(),
                                                                              ));
                                                                            },
                                                                          );
                                                                        } else if (index ==
                                                                            1) {
                                                                          // Display the current address
                                                                          return ListTile(
                                                                            leading:
                                                                                const Text("Current"),
                                                                            title:
                                                                                Text(
                                                                              cart.deliveryAddress.streetAddress,
                                                                              style: const TextStyle(color: Colors.black),
                                                                            ),
                                                                          );
                                                                        } else {
                                                                          return RadioListTile<
                                                                              int>(
                                                                            value:
                                                                                index - 2,
                                                                            groupValue:
                                                                                selectedAddressIndex,
                                                                            onChanged:
                                                                                (int? value) {
                                                                              modalSetState(() {
                                                                                selectedAddressIndex = value;
                                                                              });
                                                                            },
                                                                            title:
                                                                                Text(addresses[index - 2].streetAddress),
                                                                          );
                                                                        }
                                                                      },
                                                                    ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () async {
                                                            try {
                                                              String
                                                                  snackBarMessage;
                                                              if (selectedAddressIndex !=
                                                                      null &&
                                                                  selectedAddressIndex! <
                                                                      addresses
                                                                          .length) {
                                                                showAddress =
                                                                    false;
                                                                setDefaultAddress(
                                                                        addresses[selectedAddressIndex!]
                                                                            .id)
                                                                    .then(
                                                                        (address) {
                                                                  if (address !=
                                                                      null) {
                                                                    cart.deliveryAddress =
                                                                        address;
                                                                  }
                                                                });
                                                                snackBarMessage =
                                                                    'Delivery address set to: ${addresses[selectedAddressIndex!].streetAddress}';
                                                                Navigator.pop(
                                                                    context);
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                        snackBarMessage),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .green,
                                                                  ),
                                                                );
                                                              } else {
                                                                snackBarMessage =
                                                                    'No Address Selected';
                                                                if (!mounted) {
                                                                  return; // Check if the widget is still mounted
                                                                }
                                                                showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) {
                                                                      Future.delayed(
                                                                          const Duration(
                                                                              seconds: 1),
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop(true);
                                                                      });
                                                                      return const AlertDialog(
                                                                        title: Text(
                                                                            'No Address Selected'),
                                                                      );
                                                                    });
                                                              }

                                                              // Close the bottom sheet
                                                            } catch (error) {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                      'Failed to set default address'),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                Colors.white,
                                                            backgroundColor: Colors
                                                                .deepPurpleAccent, // Button color
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8), // Smaller rounded corners for a squarish look
                                                            ),
                                                            elevation:
                                                                5, // Floating effect
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal:
                                                                  35, // Slightly more horizontal padding
                                                              vertical:
                                                                  18, // Slightly more vertical padding
                                                            ),
                                                          ),
                                                          child: const Text(
                                                              "Deliver To Address"),
                                                        ),
                                                        const SizedBox(
                                                          height: 5,
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
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
                                        ), // No background color for the first child
                                        child: Center(
                                          child: Text(
                                            cart.deliveryAddress.streetAddress,
                                            style: GoogleFonts.cantoraOne(
                                                fontSize: 15,
                                                fontStyle: FontStyle.normal,
                                                color: Colors.black),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            softWrap: false,
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
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                        childAspectRatio: 0.7,
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
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding:
            const EdgeInsets.only(bottom: 22, top: 10, left: 15, right: 15),
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
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Squarish shape
                ),
              ),
              child: const Text(
                'Home',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Squarish shape
                ),
              ),
              child: const Text(
                'Cart',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.shade100,
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        padding: const EdgeInsets.only(left: 2, right: 2, bottom: 1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                image,
                fit: BoxFit.cover,
                height: 69.0,
              ),
              Text(
                categoryName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    height: 1.1), // Adjusting the line spacing here
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBottomSheet(BuildContext context, CartModel cart) async {
    //var cart = context.watch<CartModel>(); // or context.watch<CartModel>();

    getAllAddresses().then((_) {
      showModalBottomSheet(
        context: context,
        isDismissible: false, // Prevent dismissing by tapping outside
        enableDrag: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter modalSetState) {
              return Container(
                padding: const EdgeInsets.all(10),
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.90,
                decoration: const BoxDecoration(
                  // other decoration properties like color, border, etc.
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10), // Adjust the radius as needed
                    topRight:
                        Radius.circular(10), // Adjust the radius as needed
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.80,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 30),
                      decoration: BoxDecoration(
                        color: Colors.white, // Grey background
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                        border: Border.all(
                          color: Colors.deepPurpleAccent, // Border color
                          width: 1.0, // Border width
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.2), // Shadow color
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(
                                0, 3), // Changes position of shadow
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Select Address",
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: isLoadingGetAddress
                          ? ListView.builder(
                              itemCount:
                                  5, // Display 5 skeleton items for example
                              itemBuilder: (BuildContext context, int index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 15.0),
                                  child: Container(
                                    height: 20.0, // Height of the skeleton item
                                    width: double.infinity,
                                    color: Colors.grey[
                                        300], // Light grey color for the skeleton
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: addresses.length +
                                  2, // Two more than the addresses for the 'add' option and the current address
                              itemBuilder: (BuildContext context, int index) {
                                if (index == 0) {
                                  return ListTile(
                                    // <-- You missed the return here
                                    leading:
                                        const Icon(Icons.add), // An add icon
                                    title: const Text("Add New Address"),
                                    onTap: () {
                                      Navigator.of(context)
                                          .pushReplacement(MaterialPageRoute(
                                        builder: (context) =>
                                            const AddressScreen(),
                                      ));
                                    },
                                  );
                                } else if (index == 1) {
                                  // Display the current address
                                  return ListTile(
                                    leading: const Text("Current"),
                                    title: Text(
                                      cart.deliveryAddress.streetAddress,
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                  );
                                } else {
                                  return RadioListTile<int>(
                                    value: index - 2,
                                    groupValue: selectedAddressIndex,
                                    onChanged: (int? value) {
                                      modalSetState(() {
                                        selectedAddressIndex = value;
                                      });
                                    },
                                    title: Text(
                                        addresses[index - 2].streetAddress),
                                  );
                                }
                              },
                            ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          String snackBarMessage;
                          if (selectedAddressIndex != null &&
                              selectedAddressIndex! < addresses.length) {
                            showAddress = false;
                            setDefaultAddress(
                                    addresses[selectedAddressIndex!].id)
                                .then((address) {
                              if (address != null) {
                                cart.deliveryAddress = address;
                              }
                            });
                            snackBarMessage =
                                'Delivery address set to: ${addresses[selectedAddressIndex!].streetAddress}';
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(snackBarMessage),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            snackBarMessage = 'No Address Selected';
                            if (!mounted) {
                              return; // Check if the widget is still mounted
                            }
                            showDialog(
                                context: context,
                                builder: (context) {
                                  Future.delayed(const Duration(seconds: 1),
                                      () {
                                    Navigator.of(context).pop(true);
                                  });
                                  return const AlertDialog(
                                    title: Text('No Address Selected'),
                                  );
                                });
                          }

                          // Close the bottom sheet
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to set default address'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            Colors.deepPurpleAccent, // Button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              8), // Smaller rounded corners for a squarish look
                        ),
                        elevation: 5, // Floating effect
                        padding: const EdgeInsets.symmetric(
                          horizontal: 35, // Slightly more horizontal padding
                          vertical: 18, // Slightly more vertical padding
                        ),
                      ),
                      child: const Text(
                        "Deliver To Address",
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    )
                  ],
                ),
              );
            },
          );
        },
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isMounted = true;
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _isMounted = false;
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
                        context.push('/setting');
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
