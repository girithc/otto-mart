import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/catalog_screen.dart';
import 'package:pronto/catalog/item/api_client_item.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:pronto/search/search_screen.dart';
import 'package:provider/provider.dart';

class CategoryItemsPage extends StatelessWidget {
  final int categoryID;
  final String categoryName;
  const CategoryItemsPage(
      {super.key, required this.categoryID, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CategoryItemsAppBar(
        categoryName: categoryName,
        categoryId: categoryID,
      ),
      body: CategoryItemsBody(
        categoryId: categoryID,
        storeId: 1,
      ),
      bottomNavigationBar: const CategoryItemsBottomBar(),
    );
  }
}

class CategoryItemsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String categoryName;
  final int categoryId;

  const CategoryItemsAppBar(
      {required this.categoryName, required this.categoryId, Key? key})
      : super(key: key);

  @override
  Size get preferredSize =>
      const Size.fromHeight(65); // Increased height to accommodate content

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      child: Container(
        padding: const EdgeInsets.only(top: 10),
        margin: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey,
            width: 1.0, // Adjust the border width as needed
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              CrossAxisAlignment.end, // Aligns children to the edges
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 1.0, // Adjust the border width as needed
                ),
              ),
              width: MediaQuery.of(context).size.width * 0.15,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_outlined,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 1.0, // Adjust the border width as needed
                ),
              ),
              width: MediaQuery.of(context).size.width * 0.69,
              child: Text(
                categoryName,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const Spacer(), // Expands to fill available space
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 1.0, // Adjust the border width as needed
                ),
              ),
              width: MediaQuery.of(context).size.width * 0.15,
              child: IconButton(
                //rpadding: const EdgeInsets.only(right: 15.0),
                icon: Transform.scale(
                  scale: 1.7, // Adjust the scale factor as needed
                  child: const Icon(
                    Icons.search_outlined,
                    color: Colors.black,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SearchTopLevel()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItemsBody extends StatefulWidget {
  final int categoryId;
  final int storeId;

  const CategoryItemsBody(
      {super.key, required this.categoryId, required this.storeId});

  @override
  State<CategoryItemsBody> createState() => _CategoryItemsBodyState();
}

class _CategoryItemsBodyState extends State<CategoryItemsBody> {
  final ItemApiClient apiClient = ItemApiClient();
  List<Item> items = [];
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    try {
      final fetchedItems =
          await apiClient.fetchItems(widget.categoryId, widget.storeId);
      setState(() {
        items = fetchedItems;
      });
    } catch (err) {
      //Handle Error
      setState(() {
        items = [];
      });
      _logger.e('(catalog)fetchItems error $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 6.0,
          crossAxisSpacing: 6.0,
          childAspectRatio: 0.82,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListItem(
              name: items[index].name,
              id: items[index].id,
              mrpPrice: items[index].mrpPrice,
              discount: items[index].discount,
              storePrice: items[index].storePrice,
              stockQuantity: items[index].stockQuantity,
              image: items[index].image[0],
              quantity: items[index].quantity,
              unitOfQuantity: items[index].unitOfQuantity,
              brand: items[index].brand,
              index: index % 2);
        },
      ),
    );
  }
}

class CategoryItemsBottomBar extends StatefulWidget {
  const CategoryItemsBottomBar({super.key});

  @override
  State<CategoryItemsBottomBar> createState() => _CategoryItemsBottomBarState();
}

class _CategoryItemsBottomBarState extends State<CategoryItemsBottomBar> {
  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    return BottomAppBar(
      color: Colors.white,
      shadowColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Container(
        margin: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              flex: 8,
              child: CarouselSlider(
                items: [
                  // First tab
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.lightGreenAccent,
                    ),
                    child: Center(
                      child: Text(
                        'Free Delivery Above 499',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Second tab
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.lightGreenAccent,
                    ),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            // Default text style
                            color: Colors.black,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'FLAT 5', // The part you want to emphasize
                              style: TextStyle(
                                  fontSize:
                                      19.0), // Increase the font size for emphasis
                            ),
                            TextSpan(
                                text: ' to '), // Unchanged part of the text
                            TextSpan(
                              text:
                                  '50% Discount', // The second part you want to emphasize
                              style: TextStyle(
                                  fontSize:
                                      19.0), // Increase the font size for emphasis
                            ),
                            TextSpan(
                                text:
                                    ' on All Items'), // Unchanged part of the text
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height * 0.06,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  //aspectRatio: 16 / 9,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enableInfiniteScroll: true,
                  autoPlayAnimationDuration: Duration(
                    seconds: 3,
                  ),
                  viewportFraction: 0.95,
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: ElevatedButton(
                onPressed: () async {
                  const storage = FlutterSecureStorage();

                  // Read the cartId from storage
                  String? cartId = await storage.read(key: 'cartId');

                  // Check if cartId is null
                  if (cartId == null) {
                    // If cartId is null, navigate to MyPhone()
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyPhone()),
                    );
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyCart()));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: cart.itemList.isNotEmpty
                    ? (cart.itemList.length > 1
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart_outlined),
                              const SizedBox(
                                width: 10,
                              ),
                              Text('${cart.numberOfItems.toString()} Items'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart_outlined),
                              const SizedBox(
                                width: 10,
                              ),
                              Text('${cart.numberOfItems.toString()} Item'),
                            ],
                          ))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined),
                          SizedBox(
                            width: 10,
                          ), // Add your desired icon here
                          // Add some spacing between the icon and text
                          Text('Cart'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
