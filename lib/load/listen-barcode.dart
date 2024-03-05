import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:packer/load/loaditem.dart';
import 'package:packer/main.dart';
import 'package:packer/load/add-item.dart';
import 'package:packer/utils/constants.dart';
import 'package:packer/utils/network/service.dart';

class ListenBarcodePage extends StatefulWidget {
  const ListenBarcodePage({super.key});

  @override
  State<ListenBarcodePage> createState() => _ListenBarcodePageState();
}

class _ListenBarcodePageState extends State<ListenBarcodePage> {
  String _scanBarcodeResult = '-1';
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
      _fetchItemDetails(_scanBarcodeResult);
    }

    if (!mounted) {
      return null;
    }
    return null;
  }

  Future<void> _fetchItemDetails(String barcode) async {
    String? selectedColumn;
    int? selectedRow;

    if (barcode != '-1') {
      var url = Uri.parse('$baseUrl/packer-find-item');

      if (barcode.isEmpty) {
        throw Exception('(ItemDetailApiClient) Parameters are not valid');
      }

      var bodyParams = {'barcode': barcode, 'store_id': 1};
      var headers = {'Content-Type': 'application/json'};

      print("Body Params $bodyParams");

      try {
        final networkService = NetworkService();
        final int storeId = 1;
        Map<String, dynamic> data = {
          "store_id": storeId,
          "barcode": barcode,
        };
        final response = await networkService.postWithAuth('/packer-find-item',
            additionalData: data);

        print("Respone: ${response.body}");
        if (response.statusCode == 200) {
          final dynamic jsonData = json.decode(response.body);

          final item = FindItemResponse.fromJson(jsonData);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoadItem(findItem: item)),
          );
        } else {
          print(response.body);
        }
      } catch (e) {
        print("Exception $e");
        throw Exception(e);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to MyHomePage using Navigator.push
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyHomePage()),
            );
          },
        ),
        title: const Text(''), // Optional: if you want a title
      ),
      body: BarcodeKeyboardListener(
        onBarcodeScanned: (String code) async {
          _fetchItemDetails(code).then(
            (value) => {{}},
          );
          // Close the listening dialog
          // Set the barcode in your state, if needed
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Listening To Scanner',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator()
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: MediaQuery.of(context).size.height * 0.22,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  scanBarcode();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 108, 55, 255),

                  padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20), // Increase padding inside the button
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Phone Scan',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.01,
                    ),
                    const Icon(
                      Icons.phone_android_outlined,
                      color: Colors.white,
                      size: 35,
                    )
                  ],
                ),
              ),
            ),
            /*
            SizedBox(
              width: MediaQuery.of(context).size.height * 0.01,
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  scanBarcode().then(
                    (value) => {
                      if (value != null)
                        {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AddItemScreen(item: value)),
                          ),
                        }
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 108, 55, 255),

                  padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20), // Increase padding inside the button
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_outlined,
                      color: Colors.white,
                      size: 35,
                    )
                  ],
                ),
              ),
            ),
            */
          ],
        ),
      ),
    );
  }
}

class FindItemResponse {
  final String itemName;
  final int itemId;
  final int? shelfHorizontal; // Make this nullable
  final String? shelfVertical; // Make this nullable

  FindItemResponse({
    required this.itemName,
    required this.itemId,
    this.shelfHorizontal, // Now nullable
    this.shelfVertical, // Now nullable
  });

  factory FindItemResponse.fromJson(Map<String, dynamic> json) {
    return FindItemResponse(
      itemName: json['item_name'],
      itemId: json['item_id'],
      shelfHorizontal: json[
          'shelf_horizontal'], // This can now be null without causing an error
      shelfVertical: json[
          'shelf_vertical'], // This can now be null without causing an error
    );
  }
}
