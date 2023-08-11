// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/catalog/api_client_catalog.dart';
import 'package:pronto/catalog/api_client_item.dart';
import 'package:pronto/catalog/catalog.dart';
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
      appBar: CustomAppBar(
        categoryName: widget.categoryName,
      ),
      body: ChangeNotifierProvider(
        create: (context) => CatalogProvider(),
        child:
            ListOfItems(myString: widget.categoryName, categories: categories),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String categoryName;
  const CustomAppBar({required this.categoryName, Key? key}) : super(key: key);

  @override
  Size get preferredSize =>
      const Size.fromHeight(80); // Increased height to accommodate content

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
                GestureDetector(
                  // GestureDetector captures taps on the input field
                  onTap: () {
                    // Prevent the focus from being triggered when tapping on the input field
                    // The empty onTap handler ensures that the tap event is captured here
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.6,
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
                              fontSize: 15,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search Groceries',
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
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.1,
                  child: IconButton(
                      padding: const EdgeInsets.only(right: 15.0),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MyCart()));
                      }),
                )
              ],
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

class ListOfItems extends StatefulWidget {
  final String myString;
  final List<Category> categories;

  // Constructor for the widget that takes the string as a parameter
  const ListOfItems(
      {required this.myString, required this.categories, Key? key})
      : super(key: key);

  @override
  State<ListOfItems> createState() => _ListOfItemsState();
}

class _ListOfItemsState extends State<ListOfItems> {
  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final categoryId = catalogProvider.catalog.categoryID;
    final storeId = catalogProvider.catalog.storeID;

    return Container(
      padding: const EdgeInsets.only(left: 0, top: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            categoryId.toString(),
            //myString,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First section consuming 2 columns
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.0),
                      borderRadius: BorderRadius.circular(
                          4.0), // Optional: Add rounded corners
                    ),
                    child: ListView.builder(
                      shrinkWrap: true, // Add this line to remove the padding
                      itemCount: widget.categories.length,
                      itemBuilder: (context, index) {
                        return CategoryItem(
                            categoryID: widget.categories[index].id,
                            categoryName: widget.categories[index].name);
                      },
                    ),
                  ),
                ),

                // Second section consuming 8 columns
                ItemCatalog(
                  categoryId: categoryId,
                  storeId: storeId,
                )
              ],
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

  Future<void> fetchItems() async {
    try {
      final fetchedItems =
          await apiClient.fetchItems(widget.categoryId, widget.storeId);
      setState(() {
        items = fetchedItems;
      });
    } catch (err) {
      //Handle Error
      print('(catalog)fetchItems error $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 8,
      child: Container(
        padding: EdgeInsets.zero,
        color: const Color.fromARGB(255, 212, 187, 255),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 0.0,
            crossAxisSpacing: 0.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListItem(index: index);
          },
        ),
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final int categoryID;
  final String categoryName;

  const CategoryItem(
      {required this.categoryID, required this.categoryName, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Center(
          child: Text(
        categoryName,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      )),
      onTap: () {
        final catalogProvider = context.read<CatalogProvider>();
        catalogProvider
            .setCatalog(Catalog(categoryID: categoryID, storeID: 1, items: []));
      },
    );
  }
}

class ListItem extends StatelessWidget {
  final int index;
  const ListItem({required this.index, super.key});

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>(); // Access the CartModel instance

    return Card(
      color: Colors.white,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0),
      ),
      margin: const EdgeInsets.only(
        top: 1.0,
        left: 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text('Tile $index'),
          ),
          const Spacer(), // Space filler to push the Price and Button to the bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'Price',
                  style: TextStyle(fontSize: 16),
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
                      productId: '$index',
                      productName: 'List Tile $index',
                      price: index,
                      quantity: 1,
                    );
                    cart.addItemToCart(cartItem);
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
