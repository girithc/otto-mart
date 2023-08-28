// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/category/api_client_catalog.dart';
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
        print(categories[1].name);
      });
    } catch (err) {
      print('(catalog)fetchCategories error $err');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                flex: 5,
                child: CarouselSlider(
                  options: CarouselOptions(
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 3.5,
                      viewportFraction: 1.0),
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
              Expanded(
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons
                          .shopping_cart_outlined), // Add your desired icon here
                      SizedBox(
                          width:
                              10), // Add some spacing between the icon and text
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
        ? widget.categories[0].id
        : catalogProvider.catalog.categoryID;
    final storeId = catalogProvider.catalog.storeID;

    return Container(
      padding: const EdgeInsets.only(left: 0, top: 4),
      margin: EdgeInsets.zero,
      height: MediaQuery.of(context).size.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First section consuming 2 columns
          Expanded(
            flex: 2,
            child: Material(
              elevation: 4.0,
              child: Card(
                surfaceTintColor: Colors.white,
                shadowColor: Colors.grey,
                margin: EdgeInsets.zero,
                child: ListView.builder(
                  itemCount: widget.categories.length,
                  itemBuilder: (context, index) {
                    return CategoryItem(
                      categoryID: widget.categories[index].id,
                      categoryName: widget.categories[index].name,
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
      print('(catalog)fetchItems error $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      color: Colors.white,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 0.0,
          crossAxisSpacing: 0.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListItem(
              name: items[index].name,
              id: items[index].id,
              price: items[index].price,
              stockQuantity: items[index].stockQuantity,
              index: index % 2);
        },
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final int categoryID;
  final String categoryName;
  final bool isSelected;

  const CategoryItem(
      {required this.categoryID,
      required this.categoryName,
      required this.isSelected,
      super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      splashColor: Colors.white,
      selected: isSelected ? true : false,
      selectedTileColor: Colors.purpleAccent,
      selectedColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 2.0),
      title: Center(
          child: Text(
        categoryName,
        textAlign: TextAlign.center,
        style: isSelected
            ? const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
            : const TextStyle(fontSize: 12),
      )),
      onTap: () {
        final catalogProvider = context.read<CatalogProvider>();
        catalogProvider.setCatalog(Catalog(
            categoryID: categoryID, storeID: 1, categoryName: categoryName));
      },
    );
  }
}

class ListItem extends StatelessWidget {
  final String name;
  final int id;
  final int price;
  final int stockQuantity;
  final int index;
  const ListItem(
      {required this.name,
      required this.id,
      required this.price,
      required this.stockQuantity,
      required this.index,
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
              price: price,
              stockQuantity: stockQuantity,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color.fromARGB(255, 200, 183, 246)),
          borderRadius: BorderRadius.circular(2.0),
        ),
        margin: index == 0
            ? const EdgeInsets.only(
                top: 1.0,
                left: 4.0,
              )
            : const EdgeInsets.only(top: 1.0, left: 4.0, right: 4.0),
        child: Card(
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(name),
              ),
              const Spacer(), // Space filler to push the Price and Button to the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      price.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(1),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        final cartItem = CartItem(
                            productId: id.toString(),
                            productName: name,
                            price: price,
                            quantity: 1,
                            stockQuantity: stockQuantity);
                        cart.addItemToCart(cartItem);
                      },
                      child: itemIndexInCart != -1
                          ? Container(
                              decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                      255, 140, 98, 255), // Add border
                                  borderRadius: BorderRadius.circular(3.0)),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        context
                                            .read<CartModel>()
                                            .removeItem(itemId: id.toString());
                                      },
                                      child: const Icon(
                                        Icons.horizontal_rule,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      cart.items[itemIndexInCart].quantity
                                          .toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        cart.addItemToCart(CartItem(
                                            productId: id.toString(),
                                            productName: name,
                                            price: price,
                                            stockQuantity: stockQuantity));
                                      },
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          : const Text(
                              'Add +',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      const Size.fromHeight(42); // Increased height to accommodate content

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
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Aligns children to the edges
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
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 1.0, // Adjust the border width as needed
                ),
              ),
              width: MediaQuery.of(context).size.width * 0.69,
              child: Center(
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
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
