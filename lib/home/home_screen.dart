import 'dart:async';
import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:pronto/home/address/address_screen.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/catalog_screen.dart';
import 'package:pronto/category_items/category_items_screen.dart';
import 'package:pronto/setting/setting_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/home/api_client_home.dart';
import 'package:pronto/home/components/network_utility.dart';
import 'package:pronto/home/models/place_auto_complete_response.dart';
import 'package:pronto/home/models/prediction_auto_complete.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:pronto/search/search_screen.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final HomeApiClient apiClient = HomeApiClient('https://localhost:3000');
  List<Category> categories = [];
  List<Category> promotions = [];
  List<Address> addresses = [];

  late AnimationController _buttonController;
  late Animation<Color?> _colorAnim;
  late AnimationController _textSwitchController;

  bool isLoggedIn = false;
  bool isAddress = false;
  bool _isMounted = false;
  bool showDialogVisible = false;
  bool isLoadingGetAddress = true;

  String customerId = "0";
  String phone = "0";
  String cartId = "0";
  String streetAddress = "";
  int? selectedAddressIndex;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchPromotions();
    retrieveCustomerInfo();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 2100),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnim = ColorTween(
      begin: Colors.deepPurpleAccent,
      end: Colors.pinkAccent,
    ).animate(_buttonController);
  }

  Future<void> retrieveCustomerInfo() async {
    const storage = FlutterSecureStorage();

    String? storedCustomerId = await storage.read(key: 'customerId');
    String? storedPhone = await storage.read(key: 'phone');
    String? storedCartId =
        await storage.read(key: 'cartId'); // Get cartId from secure storage

    //CartModel cartModel = CartModel(storedCustomerId!);
    //Address? deliveryAddress = cartModel.deliveryAddress;

    setState(() {
      customerId = storedCustomerId!;
      phone = storedPhone ?? "0";
      cartId = storedCartId ?? "0"; // Set the cartId

      isLoggedIn = customerId.isNotEmpty && customerId != "0";
    });
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
        print("address Response Not Empty ${response.contentLength}");
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Address> items =
            jsonData.map((item) => Address.fromJson(item)).toList();
        setState(() {
          print("Success");
          addresses = items;
          isLoadingGetAddress = false;
        });
      } else {
        setState(() {
          print("Empty Response");
          isLoadingGetAddress = false;
        });
        print("Error: ${response.reasonPhrase}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    print("DeliveryAddress.ID ${cart.deliveryAddress.id}");
    print("Customer Id: $customerId");
    if (cart.deliveryAddress.id < 0) {
      // Set showDialogVisible to false when streetAddress is populated
      showDialogVisible = true;
    } else {
      showDialogVisible = false;
    }
    return Scaffold(
      appBar: const HomeScreenAppBar(),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          // <-- Using CustomScrollView
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Consumer<CartModel>(
                builder: (context, cart, child) {
                  //print("Address : ${cart.deliveryAddress.streetAddress}");
                  if (cart.deliveryAddress.id < 0) {
                    // Set showDialogVisible to false when streetAddress is populated
                    showDialogVisible = true;
                  }
                  if (showDialogVisible) {
                    // Show the dialog only when showDialogVisible is true
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_isMounted) {
                        // Check if state is still mounted
                        _showMyDialog(context);
                      }
                    });
                  }
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
                                      isDismissible: true,
                                      builder: (BuildContext context) {
                                        return StatefulBuilder(
                                          builder: (BuildContext context,
                                              StateSetter modalSetState) {
                                            return Container(
                                              padding: const EdgeInsets.all(10),
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.65,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.95,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    "Change Address",
                                                    style:
                                                        TextStyle(fontSize: 24),
                                                  ),
                                                  const Divider(),
                                                  Expanded(
                                                    child: isLoadingGetAddress
                                                        ? ListView.builder(
                                                            itemCount:
                                                                5, // Display 5 skeleton items for example
                                                            itemBuilder:
                                                                (BuildContext
                                                                        context,
                                                                    int index) {
                                                              return Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        10.0,
                                                                    horizontal:
                                                                        15.0),
                                                                child:
                                                                    Container(
                                                                  height:
                                                                      20.0, // Height of the skeleton item
                                                                  width: double
                                                                      .infinity,
                                                                  color: Colors
                                                                          .grey[
                                                                      300], // Light grey color for the skeleton
                                                                ),
                                                              );
                                                            },
                                                          )
                                                        : ListView.builder(
                                                            itemCount: addresses
                                                                    .length +
                                                                2, // Two more than the addresses for the 'add' option and the current address
                                                            itemBuilder:
                                                                (BuildContext
                                                                        context,
                                                                    int index) {
                                                              if (index == 0) {
                                                                return ListTile(
                                                                  // <-- You missed the return here
                                                                  leading:
                                                                      const Icon(
                                                                          Icons
                                                                              .add), // An add icon
                                                                  title: const Text(
                                                                      "Add New Address"),
                                                                  onTap: () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pushReplacement(
                                                                            MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              const AddressScreen(),
                                                                    ));
                                                                  },
                                                                );
                                                              } else if (index ==
                                                                  1) {
                                                                // Display the current address
                                                                return ListTile(
                                                                  leading:
                                                                      const Text(
                                                                          "Current"),
                                                                  title: Text(
                                                                    cart.deliveryAddress
                                                                        .streetAddress,
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .black),
                                                                  ),
                                                                );
                                                              } else {
                                                                return RadioListTile<
                                                                    int>(
                                                                  value:
                                                                      index - 2,
                                                                  groupValue:
                                                                      selectedAddressIndex,
                                                                  onChanged: (int?
                                                                      value) {
                                                                    modalSetState(
                                                                        () {
                                                                      selectedAddressIndex =
                                                                          value;
                                                                    });
                                                                  },
                                                                  title: Text(addresses[
                                                                          index -
                                                                              2]
                                                                      .streetAddress),
                                                                );
                                                              }
                                                            },
                                                          ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      if (selectedAddressIndex !=
                                                          null) {
                                                        // TODO: Send the HTTP POST request to make the selected address the default address.
                                                        Address
                                                            selectedAddress =
                                                            addresses[
                                                                selectedAddressIndex!];

                                                        // Make sure to serialize 'selectedAddress' accordingly before sending.
                                                      }
                                                    },
                                                    child: const Text(
                                                        "Make Default Address"),
                                                  ),
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
                                    borderRadius: BorderRadius.circular(4.0),
                                    border: Border.all(
                                        color: Colors.deepPurpleAccent),
                                    boxShadow: const [
                                      BoxShadow(
                                        color:
                                            Color.fromARGB(255, 248, 219, 253),
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
                                    image:
                                        AssetImage("assets/images/store.png"),
                                    opacity: 0.9,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                  border: Border.all(
                                      color: Colors.deepPurpleAccent),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromARGB(255, 248, 219, 253),
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
                        alignment:
                            Alignment.centerLeft, // Align text to the left
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
            // This is the GridView, wrapped inside a SliverPadding
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: 0.8,
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
            // Add other content here if needed
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
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: Colors.deepPurpleAccent),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(255, 248, 219, 253),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 3),
            ),
          ],
        ),
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

  Future<void> _showMyDialog(BuildContext context) async {
    if (showDialogVisible) {
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.8, // 80% of screen width
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(
                  color: Colors.deepPurple,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.25),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(
                        1, 1), // 3D effect by adjusting shadow position
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.85)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Otto Mart',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.deepPurpleAccent,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.pink,
                      decorationThickness: 0.0,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text: 'Enter Delivery Address',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.pink,
                        decorationThickness: 0.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) {
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(
                            builder: (context) => const AddressScreen(),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorAnim.value,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 12.0,
                          ),
                        ),
                        child: const Text(
                          'Add Address+',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isMounted = true;
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _textSwitchController.dispose();
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
                            )));
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
                        //homePageState._openBottomSheet();

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MyPhone()));
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
                  color: Colors.black,
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
                  color: Colors.black,
                  padding: const EdgeInsets.only(right: 15.0),
                  icon: const Icon(Icons.person_outline),
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingScreen()));
                    /*
                    
                    */
                  },
                ),
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
