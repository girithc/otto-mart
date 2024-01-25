// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
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
        child: Container(
          margin: EdgeInsets.zero,
          padding:
              const EdgeInsets.only(bottom: 25, left: 10, right: 10, top: 10),
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const MyCart()));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: cart.numberOfItems > 0
                ? (cart.numberOfItems > 1
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

    final storeId = catalogProvider.catalog.storeID;

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
                //surfaceTintColor: Colors.white,
                //shadowColor: Colors.grey,
                margin: EdgeInsets.zero,
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
              storeId: storeId == 0 ? 1 : storeId,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemCatalog extends StatefulWidget {
  final int categoryId;
  final int storeId;

  const ItemCatalog(
      {required this.categoryId, required this.storeId, super.key});

  @override
  State<ItemCatalog> createState() => _ItemCatalogState();
}

class _ItemCatalogState extends State<ItemCatalog> {
  final ItemApiClient apiClient = ItemApiClient('https://localhost:3000');
  List<Item> items = [];
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  @override
  void didUpdateWidget(covariant ItemCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId ||
        widget.storeId != oldWidget.storeId) {
      fetchItems();
    }
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
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 0.0,
            crossAxisSpacing: 0.0,
            childAspectRatio: 0.638),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListItem2(
              name: items[index].name,
              id: items[index].id,
              mrpPrice: items[index].mrpPrice,
              discount: items[index].discount,
              storePrice: items[index].storePrice,
              stockQuantity: items[index].stockQuantity,
              image: items[index].image,
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
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.pinkAccent,
                    Colors.pinkAccent.shade200,
                    Colors.white,
                  ],
                  stops: const [
                    0.8,
                    0.9,
                    1.0
                  ], // Adjust these stops for smooth transition
                )
              : null, // No gradient when not selected
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        child: Center(
          child: Text(
            categoryName,
            textAlign: TextAlign.center,
            style: isSelected
                ? const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500)
                : const TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class ListItem2 extends StatelessWidget {
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
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>(); // Access the CartModel instance
    var itemIndexInCart =
        cart.items.indexWhere((item) => item.productId == id.toString());
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
                brand: brand,
                productName: name,
                productId: id,
                mrpPrice: mrpPrice,
                storePrice: storePrice,
                discount: discount,
                stockQuantity: stockQuantity,
                image: image,
                quantity: quantity,
                unitOfQuantity: unitOfQuantity,
              ),
            ),
          );
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 1.0),
              borderRadius: BorderRadius.circular(3.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey
                      .withOpacity(0.1), // Shadow color with some opacity
                  spreadRadius: 2, // Extent of the shadow
                  blurRadius: 3, // Blur effect
                  offset: const Offset(0, 2), // Changes position of shadow
                ),
              ],
            ),
            margin: index == 0
                ? const EdgeInsets.only(
                    top: 1,
                    left: 2,
                  )
                : const EdgeInsets.only(top: 1, left: 2.0, right: 2.0),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                  child: Center(
                    child: Image.network(
                      image,
                      height: MediaQuery.of(context).size.height * 0.16,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace? stackTrace) {
                        return Container(
                          height: 120,
                          color: Colors.grey[200],
                          alignment: Alignment.center,
                          child: const Center(
                            child: Text(
                              'no image',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    margin: const EdgeInsets.only(top: 2.0),
                    alignment: Alignment.centerLeft,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.0),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      name,
                      maxLines: 2,
                      style: GoogleFonts.hind(
                        textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                  child: Container(
                    margin: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    height: 17,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.0),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      '$quantity $unitOfQuantity',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.2),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
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
                        Column(children: [
                          Text(
                            '$mrpPrice',
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.black54,
                            ),
                          ),
                          Text(
                            '\u{20B9}$storePrice',
                            style: const TextStyle(fontSize: 14),
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
                                    borderRadius: BorderRadius.circular(10.0)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        context
                                            .read<CartModel>()
                                            .removeItem(itemId: id.toString());
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
                                        cart.addItemToCart(CartItem(
                                            productId: id.toString(),
                                            productName: name,
                                            price: mrpPrice,
                                            soldPrice: storePrice,
                                            quantity: 1,
                                            stockQuantity: stockQuantity,
                                            image: image));
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
                                        productId: id.toString(),
                                        productName: name,
                                        price: mrpPrice,
                                        soldPrice: storePrice,
                                        quantity: 1,
                                        stockQuantity: stockQuantity,
                                        image: image,
                                      );
                                      cart.addItemToCart(cartItem);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      surfaceTintColor: Colors.white,
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.all(2),
                                      side: const BorderSide(
                                        width: 1.0,
                                        color: Colors.pinkAccent,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      )),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                        color: Colors.pinkAccent, fontSize: 13),
                                  ),
                                ),
                              )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 5, // Adjust the position as needed
            left: 2, // Adjust the position as needed
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '\u{20B9}$discount OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
      elevation: 2.0,
      child: Container(
        padding: const EdgeInsets.only(top: 5),
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
