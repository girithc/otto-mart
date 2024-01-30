import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:http/http.dart' as http;
import 'package:packer/quick-add/add-item.dart';
import 'package:packer/utils/constants.dart';

class ListenBarcodePage extends StatefulWidget {
  const ListenBarcodePage({super.key});

  @override
  State<ListenBarcodePage> createState() => _ListenBarcodePageState();
}

class _ListenBarcodePageState extends State<ListenBarcodePage> {
  Future<ItemAdd?> _fetchItemDetails(String barcode) async {
    if (barcode != '-1') {
      var url = Uri.parse('$baseUrl/item-add-stock');

      if (barcode.isEmpty) {
        throw Exception('(ItemDetailApiClient) Parameters are not valid');
      }

      var bodyParams = {'barcode': barcode, 'store_id': 1};
      var headers = {'Content-Type': 'application/json'};

      print("Body Params $bodyParams");

      try {
        http.Response response = await http.post(url,
            headers: headers, body: json.encode(bodyParams));

        if (response.statusCode == 200) {
          final dynamic jsonData = json.decode(response.body);
          print(response.body);

          return ItemAdd.fromJson(jsonData);
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
        appBar: AppBar(),
        body: BarcodeKeyboardListener(
          onBarcodeScanned: (String code) async {
            _fetchItemDetails(code).then(
              (value) => {
                if (value != null)
                  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddItemScreen(item: value)),
                    ),
                  }
              },
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
        ));
  }
}
