import 'package:flutter/material.dart';
import 'package:master/category/categories.dart';
import 'package:master/store/store.dart';

class Stores extends StatefulWidget {
  const Stores({super.key});

  @override
  State<Stores> createState() => _StoresState();
}

class _StoresState extends State<Stores> {
  final StoreApiClient apiClient = StoreApiClient('https://localhost:3000');
  List<Store> stores = [];

  @override
  void initState() {
    super.initState();
    fetchStores();
  }

  Future<void> fetchStores() async {
    try {
      final fetchedStores = await apiClient.fetchStores();
      setState(() {
        stores = fetchedStores;
      });
    } catch (err) {
      //Handle Error
      setState(() {
        stores = [];
      });
      print('(catalog)fetchItems error $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshItems,
      child: ListView.builder(
        itemCount: stores.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return ElevatedButton(
                onPressed: () {}, child: const Text('Add Store'));
          }
          return ListTile(
            title: Text(stores[index - 1].name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Categories(
                    storeId: stores[index - 1].id,
                    storeName: stores[index - 1].name,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _refreshItems() async {
    setState(() {
      fetchStores();
    });
  }
}
