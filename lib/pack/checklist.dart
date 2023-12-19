import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:master/main.dart';
import 'package:master/utils/constants.dart';

class OrderChecklistPage extends StatefulWidget {
  const OrderChecklistPage({super.key});

  @override
  State<OrderChecklistPage> createState() => _OrderChecklistPageState();
}

class _OrderChecklistPageState extends State<OrderChecklistPage> {
  // Sample data for the list
  final List<Map<String, dynamic>> products = List.generate(
    5,
    (index) => {
      'name': 'Product ${index + 1}',
      'aisle': 'Aisle ${index + 1}',
      'checked': false, // Added 'checked' status
    },
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late List<PackedItem> packedItems;

  @override
  void initState() {
    super.initState();
    fetchPackedItems();
  }

  Future<void> fetchPackedItems() async {
    String? packerId = await _storage.read(key: "packerId");
    String? storeId = await _storage.read(key: "storeId");
    var url = Uri.parse('$baseUrl/packer-pack-order');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(
          {"store_id": int.parse(storeId!), "packer_id": int.parse(packerId!)}),
    );

    if (response.statusCode == 200) {
      setState(() {
        packedItems = (json.decode(response.body) as List)
            .map((item) => PackedItem.fromJson(item))
            .toList();
      });
    } else {
      print("Error ${response.body}");
    }
  }

  Future<bool> cancelPackOrder() async {
    String? packerId = await _storage.read(key: "packerId");
    String? storeId = await _storage.read(key: "storeId");

    var url = Uri.parse('$baseUrl/packer-cancel-order');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "packer_id": int.parse(packerId!),
        "store_id": int.parse(storeId!),
        "order_id": packedItems[0].orderId,
      }),
    );

    if (response.statusCode == 200) {
      // Handle successful response
      return true;
    } else {
      // Handle error
      print("Error ${response.body}");
      return false;
    }
  }

  bool areAllItemsChecked() {
    return products.every((product) => product['checked']);
  }

  @override
  Widget build(BuildContext context) {
    bool allItemsChecked = areAllItemsChecked();

    return Scaffold(
      appBar: AppBar(
        title: const Hero(
          tag: 'heroButton',
          child: Text(
            'Order Checklist',
            style: TextStyle(color: Colors.white),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            cancelPackOrder().then((value) => {
                  if (value)
                    {Navigator.pop(context)}
                  else
                    {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Failed To Cancel Checkout')))
                    }
                });
          },
        ),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                var product = products[index];
                return Container(
                  margin:
                      const EdgeInsets.only(left: 1.0, right: 1.0, bottom: 5.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.secondary),
                    borderRadius: BorderRadius.circular(2.0),
                    color: product['checked']
                        ? Colors.lightGreenAccent
                        : Colors
                            .white, // Change color based on 'checked' status
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 4),
                    title: Text(product['name']),
                    leading: Text(product['aisle']),
                    trailing: IconButton(
                      icon: Icon(
                        product['checked']
                            ? Icons.remove_circle_outline
                            : Icons
                                .check_circle_outline, // Change icon based on 'checked' status
                        size: 30.0,
                        color: product['checked']
                            ? Colors.deepOrangeAccent
                            : null, // Change icon color for 'checked' items
                      ),
                      onPressed: () {
                        setState(() {
                          product['checked'] =
                              !product['checked']; // Toggle 'checked' status
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            // Use Row to split the button into two parts
            children: <Widget>[
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  color: Colors.white,
                  child: ElevatedButton(
                    onPressed: areAllItemsChecked()
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MyHomePage(title: 'Otto Store')),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple, // Left side color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5), // Square shape
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                      ),
                    ),
                    child: const Text('Pack Order', // Left side text
                        style: TextStyle(color: Colors.white, fontSize: 22)),
                  ),
                ),
              ),
              Expanded(
                child: Hero(
                  tag: 'handoffbutton',
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    color: Colors.white,
                    child: ElevatedButton(
                      onPressed: allItemsChecked
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MyHomePage(
                                          title: 'Otto Store',
                                        )),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreenAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: BorderSide(
                            color: allItemsChecked
                                ? Colors.black26
                                : Colors.white, // Conditional border color
                            width: 2.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: Text(
                        'Hand Off',
                        style: TextStyle(
                          color: allItemsChecked
                              ? Colors.black
                              : Colors.white, // Conditional text color
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PackedItem {
  int orderId;
  String name;
  String brand;
  int quantity;
  String unitOfQuantity;
  int itemQuantity;
  List<String> imageURLs;

  PackedItem({
    required this.orderId,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.unitOfQuantity,
    required this.itemQuantity,
    required this.imageURLs,
  });

  factory PackedItem.fromJson(Map<String, dynamic> json) {
    return PackedItem(
      orderId: json['order_id'],
      name: json['name'],
      brand: json['brand'],
      quantity: json['quantity'],
      unitOfQuantity: json['unit_of_quantity'],
      itemQuantity: json['item_quantity'],
      imageURLs: List<String>.from(json['image_urls']),
    );
  }
}
