import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:master/item-detail/item-detail.dart';
import 'package:master/main.dart';
import 'package:master/stock/add-stock.dart';
import 'package:master/utils/constants.dart';

class OrderChecklistPage extends StatefulWidget {
  const OrderChecklistPage({super.key});

  @override
  State<OrderChecklistPage> createState() => _OrderChecklistPageState();
}

class _OrderChecklistPageState extends State<OrderChecklistPage> {
  // Sample data for the list
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<PackedItem> packedItems = [];

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
      print('response: ${response.body}');

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
      print('response: ${response.body}');
      return true;
    } else {
      // Handle error
      print("Error ${response.body}");
      return false;
    }
  }

  String? _scanBarcodeResult;
  final ItemDetailApiClient apiClient = ItemDetailApiClient();

  Future<void> scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      setState(() {
        _scanBarcodeResult = barcodeScanRes;
      });
      //_showBarcodeResultDialog(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version';
      // TODO
    }

    if (_scanBarcodeResult != '-1') {
      apiClient.fetchItemFromBarcode(_scanBarcodeResult!).then((success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddStock(item: success)),
        );
      }, onError: (error) {
        // Handle error here if fetchItemFromBarcode fails
        print("Error fetching item: $error");
      });
    }

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
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
      body: packedItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: packedItems.length,
              itemBuilder: (context, index) {
                PackedItem item = packedItems[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        // Leading widget
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (item.imageURLs.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        content: Image.network(
                                          item.imageURLs.first,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.7, // Use screen width for the image
                                          height:
                                              300, // Adjust height as needed
                                        ),
                                        actions: <Widget>[
                                          Center(
                                            child: TextButton(
                                              onPressed: () => Navigator.of(
                                                      context)
                                                  .pop(), // Close the dialog
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(Colors.white),
                                              ),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize:
                                                        20), // Optional: Change text color if needed
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.itemQuantity}x',
                                    style: const TextStyle(fontSize: 25),
                                  ),
                                  item.imageURLs.isNotEmpty
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: Image.network(
                                            item.imageURLs.first,
                                            height: 90,
                                            width: 100,
                                          ),
                                        )
                                      : const SizedBox(width: 40, height: 40),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 2.0,
                            ),
                            const Center(
                              child: Text(
                                'Aisle 1A',
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          ],
                        ),
                        // Spacer to push the trailing widget to the end

                        // Title and subtitle
                        Row(
                          children: <Widget>[
                            SizedBox(
                              width: 180,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 16),
                                  ), // Display item name
                                  Text(
                                    '${item.brand}\nQuantity: ${item.quantity} ${item.unitOfQuantity}',
                                    style: const TextStyle(fontSize: 16),
                                  ), // Display brand and quantity
                                ],
                              ),
                            ),
                            // Spacer for spacing between title and trailing icon
                            const SizedBox(width: 4.0),
                            // Trailing widget
                            const Icon(Icons.check_circle_outline_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: scanBarcode,
        backgroundColor: Colors.deepPurpleAccent,
        label: const Text(
          'Scan Item',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
