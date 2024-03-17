// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/category/api_client_catalog.dart';
import 'package:pronto/catalog/constants.dart';
import 'package:pronto/catalog/item/api_client_item.dart';
import 'package:pronto/catalog/catalog.dart';
import 'package:pronto/item/product.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:pronto/search/search_screen.dart';
import 'package:pronto/utils/network/service.dart';
import 'package:provider/provider.dart';

class MyCatalog extends StatefulWidget {
  final int categoryID;
  final String categoryName;
  const MyCatalog(
      {required this.categoryID, required this.categoryName, Key? key})
      : super(key: key);

  @override
  State<MyCatalog> createState() => _MyCatalogState();
}

class _MyCatalogState extends State<MyCatalog> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => CatalogProvider(),
          ),
        ],
        child: CatalogPage(
          categoryID: widget.categoryID,
          categoryName: widget.categoryName,
        ));
  }
}

class CatalogPage extends StatefulWidget {
  const CatalogPage(
      {required this.categoryID, required this.categoryName, super.key});
  final int categoryID;
  final String categoryName;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final CatalogApiClient apiClient = CatalogApiClient('https://localhost:3000');
  final Logger _logger = Logger();
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories =
          await apiClient.fetchCategories(widget.categoryID);
      setState(() {
        categories = fetchedCategories;
        //print(categories[1].name);
      });
    } catch (err) {
      _logger.e('(catalog)fetchCategories error $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    return Scaffold(
      appBar: CatalogAppBar(
        categoryName: widget.categoryName,
      ),
      body: ListOfItems(categories: categories),
      bottomNavigationBar: Material(
        elevation: 4.0,
        color: Colors.white,
        child: Container(
          margin: EdgeInsets.zero,
          padding:
              const EdgeInsets.only(bottom: 25, left: 10, right: 10, top: 10),
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
                        color: Colors.tealAccent,
                      ),
                      child: Center(
                        child: Text(
                          'Free Delivery Above 49',
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
                        color: Colors.tealAccent,
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
                                text:
                                    'FLAT 5', // The part you want to emphasize
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
                        MaterialPageRoute(
                            builder: (context) => const MyPhone()),
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
                      borderRadius: BorderRadius.circular(10.0),
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
      ),
    );
  }
}

class ListOfItems extends StatefulWidget {
  final List<Category> categories;

  // Constructor for the widget that takes the string as a parameter
  const ListOfItems({required this.categories, Key? key}) : super(key: key);

  @override
  State<ListOfItems> createState() => _ListOfItemsState();
}

class _ListOfItemsState extends State<ListOfItems> {
  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final categoryId = catalogProvider.catalog.categoryID == 0
        ? widget.categories.isNotEmpty
            ? widget.categories[0].id
            : 0
        : catalogProvider.catalog.categoryID;

    return Container(
      padding: const EdgeInsets.only(left: 0, top: 0),
      margin: EdgeInsets.zero,
      height: MediaQuery.of(context).size.height,
      //color: const Color.fromARGB(255, 248, 219, 253),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Colors.white, Color.fromARGB(255, 248, 219, 253)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First section consuming 2 columns
          Expanded(
            flex: 2,
            child: Material(
              elevation: 4.0,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: EdgeInsets.zero,
                color: Colors.white,
                child: ListView.builder(
                  itemCount: widget.categories.length,
                  itemBuilder: (context, index) {
                    return CategoryItem(
                      categoryID: widget.categories[index].id,
                      categoryName: widget.categories[index].name,
                      categoryImage: widget.categories[index].image,
                      isSelected: widget.categories[index].id == categoryId
                          ? true
                          : false,
                    );
                  },
                ),
              ),
            ),
          ),

          // Second section consuming 8 columns
          Expanded(
            flex: 8,
            child: ItemCatalog(
              categoryId: widget.categories.isNotEmpty
                  ? (categoryId == 0 ? widget.categories[0].id : categoryId)
                  : 0,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemCatalog extends StatefulWidget {
  final int categoryId;

  const ItemCatalog({required this.categoryId, super.key});

  @override
  State<ItemCatalog> createState() => _ItemCatalogState();
}

class _ItemCatalogState extends State<ItemCatalog> {
  final ItemApiClient apiClient = ItemApiClient();
  List<Item> items = [];
  final Logger _logger = Logger();
  final storage = const FlutterSecureStorage();

  int? storeId;

  fetchStoreId() async {
    final storeIdString = await storage.read(key: 'storeId');
    setState(() {
      storeId = int.parse(storeIdString!);
    });
  }

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  @override
  void didUpdateWidget(covariant ItemCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId) {
      fetchItems();
    }
  }

  Future<void> fetchItems() async {
    try {
      final storeIdString = await storage.read(key: 'storeId');
      storeId = int.parse(storeIdString!);

      if (storeId == null) {
        return;
      }

      final fetchedItems =
          await apiClient.fetchItems(widget.categoryId, storeId!);
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
    return storeId == null
        ? const LinearProgressIndicator()
        : Container(
            color: const Color(0xFFF2F2F2),
            padding: const EdgeInsets.only(bottom: 4),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 1.0,
                  crossAxisSpacing: 0.0,
                  childAspectRatio: 0.615),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListItem2(
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

class CategoryItem extends StatelessWidget {
  final int categoryID;
  final String categoryName;
  final String categoryImage;
  final bool isSelected;

  const CategoryItem({
    required this.categoryID,
    required this.categoryName,
    required this.categoryImage,
    required this.isSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          final catalogProvider = context.read<CatalogProvider>();
          catalogProvider.setCatalog(Catalog(
              categoryID: categoryID, storeID: 1, categoryName: categoryName));
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.pinkAccent.shade200.withOpacity(0.15),
                      Colors.pinkAccent.shade100.withOpacity(0.2),
                    ],
                    stops: const [0.1, 1.0],
                  )
                : null, // No gradient when not selected
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
          ),
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.08,
                margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                      color: Colors.deepPurpleAccent.withOpacity(0.2)),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 0,
                            blurRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 0,
                            blurRadius: 1,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Center(
                    child: categoryImage.isNotEmpty
                        ? categoryImage.contains('.avif')
                            ? AvifImage.network(
                                categoryImage,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  return Container(
                                    height: 80,
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
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.black),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Image.network(
                                categoryImage,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
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
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                  );
                                },
                              )
                        : Container(
                            child: Center(
                                child: Text(
                              "image",
                              style: TextStyle(
                                fontSize: 10,
                              ),
                            )),
                          )),
              ),
              Container(
                alignment: Alignment.bottomCenter,
                child: Text(
                  categoryName,
                  textAlign: TextAlign.center,
                  style: isSelected
                      ? const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.normal)
                      : const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
            ],
          ),
        ));
  }
}

class ListItem2 extends StatefulWidget {
  final String name;
  final int id;
  final int mrpPrice;
  final int discount;
  final int storePrice;
  final int stockQuantity;
  final int index;
  final String image;
  final String unitOfQuantity;
  final int quantity;
  final String brand;

  const ListItem2(
      {required this.name,
      required this.id,
      required this.mrpPrice,
      required this.discount,
      required this.storePrice,
      required this.stockQuantity,
      required this.image,
      required this.index,
      required this.unitOfQuantity,
      required this.quantity,
      required this.brand,
      super.key});

  @override
  State<ListItem2> createState() => _ListItem2State();
}

class _ListItem2State extends State<ListItem2> {
  notifyOutOfStock() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Center(
          child: Text(
            'Item Coming Soon !',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>(); // Access the CartModel instance
    var itemIndexInCart =
        cart.items.indexWhere((item) => item.productId == widget.id.toString());
    return GestureDetector(
      onTap: () async {
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
              builder: (context) => Product(
                brand: widget.brand,
                productName: widget.name,
                productId: widget.id,
                mrpPrice: widget.mrpPrice,
                storePrice: widget.storePrice,
                discount: widget.discount,
                stockQuantity: widget.stockQuantity,
                image: widget.image,
                quantity: widget.quantity,
                unitOfQuantity: widget.unitOfQuantity,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: (widget.index % 2 == 0)
            ? const EdgeInsets.only(left: 4, right: 2, top: 2, bottom: 2)
            : const EdgeInsets.only(left: 2, right: 4, top: 2, bottom: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: const [],
        ),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () async {
                final storage = FlutterSecureStorage();

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
                      builder: (context) => Product(
                        brand: widget.brand,
                        productName: widget.name,
                        productId: widget.id,
                        mrpPrice: widget.mrpPrice,
                        storePrice: widget.storePrice,
                        discount: widget.discount,
                        stockQuantity: widget.stockQuantity,
                        image: widget.image,
                        quantity: widget.quantity,
                        unitOfQuantity: widget.unitOfQuantity,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: const [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                          top: 0, bottom: 10, left: 0, right: 0),
                      height: MediaQuery.of(context).size.height * 0.165,
                      child: Center(
                        child: Image.network(
                          widget.image,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.16,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const Center(
                                child: Text(
                                  'no image',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Container(
                      padding: const EdgeInsets.only(left: 4.0),
                      alignment: Alignment.centerLeft,
                      height: 37,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.0),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        widget.name,
                        maxLines: 2,
                        style: GoogleFonts.hind(
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 0),
                      margin: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.0),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        '${widget.quantity} ${widget.unitOfQuantity}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.only(left: 4.0),
                      height: 40,
                      margin: const EdgeInsets.only(top: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.0),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.mrpPrice}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.black54,
                                  ),
                                ),
                                Text(
                                  '\u{20B9}${widget.storePrice}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ]),
                          itemIndexInCart != -1
                              ? Container(
                                  width: 80,
                                  height: 35,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.pinkAccent, // Add border
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          cart.addItemToCart(CartItem(
                                              productId: widget.id.toString(),
                                              productName: widget.name,
                                              price: widget.mrpPrice,
                                              soldPrice: widget.storePrice,
                                              quantity: -1,
                                              stockQuantity:
                                                  widget.stockQuantity,
                                              image: widget.image));
                                        },
                                        child: const Icon(
                                          Icons.horizontal_rule,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        cart.items[itemIndexInCart].quantity
                                            .toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 18),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          cart
                                              .addItemToCart(CartItem(
                                                  productId:
                                                      widget.id.toString(),
                                                  productName: widget.name,
                                                  price: widget.mrpPrice,
                                                  soldPrice: widget.storePrice,
                                                  quantity: 1,
                                                  stockQuantity:
                                                      widget.stockQuantity,
                                                  image: widget.image))
                                              .then((value) => {
                                                    if (value!.outOfStock ==
                                                        true)
                                                      {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Only limited quantity available: ${value.stockQuantity}'),
                                                            duration: Duration(
                                                                seconds: 2),
                                                          ),
                                                        )
                                                      }
                                                  });
                                        },
                                        child: const Icon(
                                          Icons.add,
                                          size: 26,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  width: 55,
                                  padding: EdgeInsets.zero,
                                  margin: const EdgeInsets.only(
                                      right: 2, top: 2, bottom: 4),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (widget.stockQuantity > 0) {
                                        // Create an instance of FlutterSecureStorage
                                        const storage = FlutterSecureStorage();

                                        // Read the cartId from storage
                                        String? cartId =
                                            await storage.read(key: 'cartId');

                                        // Check if cartId is null
                                        if (cartId == null) {
                                          // If cartId is null, navigate to MyPhone()
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const MyPhone()),
                                          );
                                        } else {
                                          // If cartId is not null, proceed with adding item to cart
                                          final cartItem = CartItem(
                                            productId: widget.id.toString(),
                                            productName: widget.name,
                                            price: widget.mrpPrice,
                                            soldPrice: widget.storePrice,
                                            quantity: 1,
                                            stockQuantity: widget.stockQuantity,
                                            image: widget.image,
                                          );
                                          cart.addItemToCart(cartItem);
                                        }
                                      } else {
                                        notifyOutOfStock();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                        surfaceTintColor: Colors.white,
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.all(2),
                                        side: BorderSide(
                                          width: 1.0,
                                          color: widget.stockQuantity <= 0
                                              ? Colors.greenAccent
                                              : Colors.pinkAccent,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        )),
                                    child: Text(
                                      widget.stockQuantity <= 0
                                          ? 'Notify'
                                          : 'Add',
                                      style: widget.stockQuantity <= 0
                                          ? const TextStyle(
                                              color: Colors.black, fontSize: 13)
                                          : const TextStyle(
                                              color: Colors.pinkAccent,
                                              fontSize: 13),
                                    ),
                                  ),
                                )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            widget.discount > 0
                ? Positioned(
                    top: 0, // Adjust the position as needed
                    left: 0, // Adjust the position as needed
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '\u{20B9}${widget.discount} OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            if (widget.stockQuantity <= 0)
              Container(
                height: MediaQuery.of(context).size.height * 0.155,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2), // Adjust padding as needed
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CatalogAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String categoryName;

  const CatalogAppBar({required this.categoryName, Key? key}) : super(key: key);

  @override
  Size get preferredSize =>
      const Size.fromHeight(65); // Increased height to accommodate content

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.0,
      color: Colors.white,
      shadowColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.only(top: 1),
        margin: const EdgeInsets.all(0),
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
              padding: const EdgeInsets.only(bottom: 10, top: 10),
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
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
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
                          builder: (context) => const SearchTopLevel()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
