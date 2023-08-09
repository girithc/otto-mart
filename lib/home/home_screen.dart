import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/catalog_screen.dart';
import 'package:pronto/home/api_client_home.dart';
import 'package:pronto/product.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final HomeApiClient apiClient = HomeApiClient('https://localhost:3000');
  List<Category> categories = [];

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
      //Handle Error
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
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
                        return _buildCategoryContainer(
                            context, categories[index].name);
                      },
                    ),
                  )),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  CarouselSlider(
                    items: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Product(
                                productName: 'Product-1',
                              ), // Replace ProductDetailPage with your desired destination page
                            ),
                          );
                        },
                        child: Card(
                          elevation: 5,
                          shadowColor: Colors.transparent,
                          color: Colors.white,
                          child: SizedBox(
                            width: 300,
                            height: 500,
                            child: Stack(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Product-1',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Spacer(),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Add your button logic here
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.0, // Adjust the value for squareness
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              16.0, // Adjust the horizontal padding
                                          vertical:
                                              8.0, // Adjust the vertical padding
                                        ),
                                      ),
                                      child: const Text('Add'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Product(
                                productName: 'Product-2',
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 5,
                          shadowColor: Colors.transparent,
                          color: Colors.white,
                          child: SizedBox(
                            width: 300,
                            height: 500,
                            child: Stack(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Product-2',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Spacer(),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Add your button logic here
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              16.0, // Adjust the horizontal padding
                                          vertical:
                                              8.0, // Adjust the vertical padding
                                        ),
                                      ),
                                      child: const Text('Add'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Product(
                                productName: 'Product-3',
                              ), // Replace ProductDetailPage with your desired destination page
                            ),
                          );
                        },
                        child: Card(
                          elevation: 5,
                          shadowColor: Colors.transparent,
                          color: Colors.white,
                          child: SizedBox(
                            width: 300,
                            height: 500,
                            child: Stack(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Product-3',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Spacer(),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Add your button logic here
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.0, // Adjust the value for squareness
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              16.0, // Adjust the horizontal padding
                                          vertical:
                                              8.0, // Adjust the vertical padding
                                        ),
                                      ),
                                      child: const Text('Add'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Add more cards with different texts here...
                    ],

                    //Slider Container properties
                    options: CarouselOptions(
                      height: 150.0,
                      enlargeCenterPage: false,
                      autoPlay: false,
                      aspectRatio: 4 / 9,
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enableInfiniteScroll: true,
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                      viewportFraction: 0.33,
                    ),
                  ),
                ],
              ),
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

  Widget _buildCategoryContainer(BuildContext context, String categoryName) {
    return GestureDetector(
      onTap: () => {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyCatalog(
              categoryName: categoryName,
            ), // Replace ProductDetailPage with your desired destination page
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
  const CustomAppBar({super.key});

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
        backgroundColor: //Colors.deepPurpleAccent.shade100,
            Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 5.0),
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: const Text(
                    'Pronto',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  padding: const EdgeInsets.only(right: 15.0),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: () {
                    // Your notifications icon logic here
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
                    // Your notifications icon logic here
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ), // Space between the brand name and the input field
            GestureDetector(
              // GestureDetector captures taps on the input field
              onTap: () {
                // Prevent the focus from being triggered when tapping on the input field
                // The empty onTap handler ensures that the tap event is captured here
              },
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
                        // Add your custom logic for handling text input, if needed.
                        // For example, you can use the onChanged callback to get the typed text.
                        onChanged: (text) {
                          // Your custom logic here
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        toolbarHeight: 130,
        // Add any other actions or widgets to the AppBar if needed.
        // For example, you can use actions to add buttons or icons.
      ),
    );
  }
}
