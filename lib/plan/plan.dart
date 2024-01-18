import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/catalog_screen.dart';
import 'package:pronto/home/address/select/select.dart';
import 'package:pronto/home/api_client_home.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/home/tab/tab.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/search/search_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:provider/provider.dart';

class MyPlan extends StatefulWidget {
  const MyPlan({super.key});
  static const String routeName = '/MyPlanPage';

  @override
  State<MyPlan> createState() => _MyPlanState();
}

class _MyPlanState extends State<MyPlan> {
  final HomeApiClient apiClient = HomeApiClient('https://localhost:3000');
  List<Category> categories = [];
  final Logger _logger = Logger();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
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

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    //print("DeliveryAddress.ID ${cart.deliveryAddress.id}");
    int randomNumber = 8 + Random().nextInt(9);

    return Scaffold(
        appBar: AppBar(
          elevation: 2,
          automaticallyImplyLeading:
              false, // This line removes the default back button
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.white24,
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
                        onPressed: () {}),
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
            ],
          ),
          toolbarHeight: 70,
        ),
        body: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Transform.scale(
                  scale: 1.1, // Increase the size by 30%
                  child: Lottie.network(
                    'https://lottie.host/61c9c5b7-2bde-412b-adbf-27b160a88233/MpwpIRyS1u.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'to ${cart.deliveryAddress.streetAddress}, ${cart.deliveryAddress.lineOne}',
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.5, // Adjust the multiplier to increase line spacing
                ),
                textAlign:
                    TextAlign.center, // Centers each line of text horizontally
              ),
              const SizedBox(
                height: 120,
              ),
              ElevatedButton(
                onPressed: () async {
                  context.go('/select-address');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurpleAccent, // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        8), // Smaller rounded corners for a squarish look
                  ),
                  elevation: 5, // Floating effect
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, // Slightly more horizontal padding
                    vertical: 10, // Slightly more vertical padding
                  ),
                ),
                child: const Text(
                  "Change Address",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(
                height: 40,
              ),
            ],
          ),
        ));
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
        padding: const EdgeInsets.only(left: 2, right: 2, bottom: 0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.11,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      spreadRadius: 0,
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height * 0.12,
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.04,
                child: Text(
                  categoryName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      height: 1.3,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold), // Adjusting the line spacing here
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RepeatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title; // Make the title parameter optional
  //final _MyHomePageState homePageState; // Add this line

  const RepeatAppBar({this.title, super.key});

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
