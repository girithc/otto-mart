import 'package:flutter/material.dart';
import 'package:master/item-detail/item-details.dart';
import 'package:master/item/item.dart';

class Items extends StatefulWidget {
  const Items(
      {required this.categoryId, required this.categoryName, super.key});
  final int categoryId;
  final String categoryName;

  @override
  State<Items> createState() => _ItemsState();
}

class _ItemsState extends State<Items> {
  final ItemApiClient apiClient = ItemApiClient('https://localhost:3000');
  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    try {
      final fetchedItems = await apiClient.fetchItems(widget.categoryId, 1);
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4.0,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          widget.categoryName,
          style: const TextStyle(
              color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshItems, // Define the refresh function here
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(items[index].name),
              onTap: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetails(
                      itemId: items[index].id,
                      itemName: items[index].name,
                    ),
                  ),
                )
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _refreshItems() async {
    setState(() {
      fetchItems();
    });
  }
}
