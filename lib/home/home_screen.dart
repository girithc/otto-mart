import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/catalog_screen.dart';
import 'package:pronto/deprecated/cart.dart';
import 'package:pronto/home/api_client_home.dart';
import 'package:pronto/home/components/horizontal-scroll-items.dart';
import 'package:pronto/home/components/location-list-tile.dart';

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

  void _openBottomSheet() {
    if (!_isBottomSheetOpen) {
      setState(() {
        _isBottomSheetOpen = true;
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              width: MediaQuery.of(context).size.width * 0.95,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Login In To Pronto',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter Phone No.',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openAddressBottomSheet(); // Close the address bottom sheet
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        fixedSize: const Size(double.infinity, 40),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      child: const Text('Login / Signup'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ).whenComplete(
        () => setState(() {
          _isBottomSheetOpen = false;
        }),
      );
    }
  }

  void _openAddressBottomSheet() {
    if (!_isBottomSheetAddressOpen) {
      setState(() {
        _isBottomSheetAddressOpen = true;
      });
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width * 0.95,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Enter Your Address',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Divider(
                      height: 20,
                      thickness: 2,
                      color: Color.fromARGB(255, 235, 235, 235)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                            context); // Close the address bottom sheet
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        fixedSize: const Size(double.infinity, 40),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      child: const Text('Submit Address'),
                    ),
                  ),
                  const Divider(
                      height: 20,
                      thickness: 2,
                      color: Color.fromARGB(255, 235, 235, 235)),
                  LocationListTile(location: 'Juhu, Mumbai', press: () {}),
                  LocationListTile(location: 'Juhu, Mumbai', press: () {}),
                ],
              ),
            ),
          );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Your notifications icon logic here
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const MyCart()));
        },
        tooltip: 'Cart',
        child: const Icon(Icons.shopping_bag_outlined),
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 5.0),
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: TextButton(
                    onPressed: () {
                      homePageState._openBottomSheet();
                    },
                    child: const Text(
                      'Pronto',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  padding: const EdgeInsets.only(right: 15.0),
                  icon: const Icon(Icons.shopping_bag_outlined),
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
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
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
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.inversePrimary,
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
        toolbarHeight: 130,
      ),
    );
  }
}
