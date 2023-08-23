import 'package:flutter/material.dart';
import 'package:master/add-item/add-items.dart';
import 'package:master/item-detail/item-details.dart';
import 'package:master/item/item.dart';

class Items extends StatefulWidget {
  const Items(
      {required this.categoryId,
      required this.categoryName,
      required this.storeId,
      super.key});
  final int categoryId;
  final String categoryName;
  final int storeId;

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
          onRefresh: _refreshItems,
          child: ListView.builder(
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddItem(
                            categoryName: widget.categoryName,
                          ),
                        ),
                      );
                    },
                    child: const Text('Add Item'));
              }
              return ListTile(
                title: Text(items[index - 1].name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetails(
                        itemId: items[index - 1].id,
                        itemName: items[index - 1].name,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ));
  }

  Future<void> _refreshItems() async {
    setState(() {
      fetchItems();
    });
  }
}
