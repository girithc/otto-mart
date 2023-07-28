import 'package:flutter/material.dart';

import 'cart.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;
  const CategoryPage({required this.categoryName, Key? key}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        padding: const EdgeInsets.only(left: 0, top: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              widget.categoryName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First section consuming 3 columns
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.0),
                        borderRadius: BorderRadius.circular(
                            4.0), // Optional: Add rounded corners
                      ),
                      child: ListView(
                        shrinkWrap: true, // Add this line to remove the padding
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Center(
                                child: Text(
                              'Fresh Fruits',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            )),
                            onTap: () {
                              // Handle tile tap
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Center(
                              child: Text(
                                'Vegetables',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            onTap: () {
                              // Handle tile tap
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Center(
                              child: Text(
                                "Packaged Foods",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            onTap: () {
                              // Handle tile tap
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Center(
                                child: Text(
                              'Frozen Foods',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            )),
                            onTap: () {
                              // Handle tile tap
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Second section consuming 7 columns
                  Expanded(
                    flex: 8,
                    child: Container(
                      padding: EdgeInsets.zero,
                      color: Colors.deepPurpleAccent.shade100,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                // Add your content for the left column here
                                // For example, you can use a ListView.builder to display a list of card-like tiles.
                                Expanded(
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount:
                                        20, // Replace with the actual number of items in the left column
                                    itemBuilder: (context, index) {
                                      return Card(
                                        color: Colors.white,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                        margin: const EdgeInsets.only(
                                            top: 1.0, left: 1.0),
                                        child: SizedBox(
                                          width:
                                              100, // Adjust the width to make it square
                                          height:
                                              100, // Adjust the height to make it square
                                          child: ListTile(
                                            title: Text('Left Tile $index'),
                                            onTap: () {
                                              // Handle tile tap
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                // Add your content for the right column here
                                // For example, you can use another ListView.builder to display a list of card-like tiles.
                                Expanded(
                                  child: ListView.builder(
                                    itemCount:
                                        20, // Replace with the actual number of items in the right column
                                    itemBuilder: (context, index) {
                                      return Card(
                                        color: Colors.white,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                        margin: const EdgeInsets.only(
                                            top: 1, left: 1, right: 1),
                                        child: SizedBox(
                                          width:
                                              100, // Adjust the width to make it square
                                          height:
                                              100, // Adjust the height to make it square
                                          child: ListTile(
                                            title: Text('Right Tile $index'),
                                            onTap: () {
                                              // Handle tile tap
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

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
                      // Your notifications icon logic here
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CartPage()));
                    },
                  ),
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
