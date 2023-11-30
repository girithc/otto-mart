// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/category/api_client_catalog.dart';
import 'package:pronto/catalog/constants.dart';
import 'package:pronto/catalog/item/api_client_item.dart';
import 'package:pronto/catalog/catalog.dart';
import 'package:pronto/item/product.dart';
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
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        child: Container(
          margin: EdgeInsets.zero,
          child: Row(
            // Expand the Row to fill the available space
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                flex: 5,
                child: CarouselSlider(
                  options: CarouselOptions(
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 3.5,
                      autoPlayInterval: const Duration(seconds: 3),
                      viewportFraction: 0.95),
                  items: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.pinkAccent),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Center(
                        child: Text("Offer 1"),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.pinkAccent),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Center(
                        child: Text("Offer 2"),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.pinkAccent),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Center(
                        child: Text("Offer 3"),
                      ),
                    ),
                    // Add more items as needed
                  ],
                ),
              ),
              Flexible(
                flex: 4,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyCart()));
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
                      borderRadius: BorderRadius.circular(4.0),
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
            child: SizedBox(
              child: ItemCatalog(
                categoryId: widget.categories.isNotEmpty
                    ? (categoryId == 0 ? widget.categories[0].id : categoryId)
                    : 0,
                storeId: storeId == 0 ? 1 : storeId,
              ),
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

  const CategoryItem(
      {required this.categoryID,
      required this.categoryName,
      required this.categoryImage,
      required this.isSelected,
      super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      splashColor: const Color.fromRGBO(206, 157, 255, 1),
      selected: isSelected ? true : false,
      textColor: Colors.black,
      selectedColor: Colors.black,
      //contentPadding: const EdgeInsets.symmetric(vertical: 2.0),
      title: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              categoryName,
              textAlign: TextAlign.center,
              style: isSelected
                  ? const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                  : const TextStyle(fontSize: 14),
            ), // Optional: to provide some space between the text and image
            Image.network(
              categoryImage,
              fit: BoxFit.cover,
              height: 55.0,
            ) // Replace 'categoryImage' with your image URL variable
          ],
        ),
      ),
      onTap: () {
        final catalogProvider = context.read<CatalogProvider>();
        catalogProvider.setCatalog(Catalog(
            categoryID: categoryID, storeID: 1, categoryName: categoryName));
      },
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
      super.key});

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>(); // Access the CartModel instance
    var itemIndexInCart =
        cart.items.indexWhere((item) => item.productId == id.toString());
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Product(
              productName: name,
              productId: id,
              mrpPrice: mrpPrice,
              storePrice: storePrice,
              discount: discount,
              stockQuantity: stockQuantity,
              image: image,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 1.0),
              borderRadius: BorderRadius.circular(3.0),
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
                      height: 120,
                      fit: BoxFit.cover,
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
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            height: 0.9,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                      height: 17,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.0),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_offer_outlined,
                            color: Colors.deepPurple,
                            size: 15,
                          ),
                          const SizedBox(
                              width:
                                  5), // Adding some spacing between icon and text
                          Text(
                            'Add 1, Unlock offer',
                            maxLines: 2,
                            style: GoogleFonts.firaSans(
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                color: Colors.deepPurple,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      )),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    height: 37,
                    margin: const EdgeInsets.only(top: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.0),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\u{20B9}$storePrice',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          '$mrpPrice',
                          style: const TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.black54,
                          ),
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        itemIndexInCart != -1
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 2),
                                margin: const EdgeInsets.only(right: 2),
                                decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 140, 98, 255), // Add border
                                    borderRadius: BorderRadius.circular(3.0)),
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
                                        size: 21,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      cart.items[itemIndexInCart].quantity
                                          .toString(),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
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
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: EdgeInsets.zero,
                                margin: const EdgeInsets.only(
                                    right: 2, top: 2, bottom: 4),
                                child: ElevatedButton(
                                    onPressed: () {
                                      final cartItem = CartItem(
                                          productId: id.toString(),
                                          productName: name,
                                          price: mrpPrice,
                                          soldPrice: storePrice,
                                          quantity: 1,
                                          stockQuantity: stockQuantity,
                                          image: image);
                                      cart.addItemToCart(cartItem);
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
                                      'Add+',
                                      style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontSize: 13.5),
                                    )),
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
            left: 5, // Adjust the position as needed
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
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
