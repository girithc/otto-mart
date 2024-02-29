import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:packer/load/listen-barcode.dart';
import 'package:packer/utils/network/service.dart';

class LoadItem extends StatefulWidget {
  const LoadItem({super.key, required this.findItem});
  final FindItemResponse findItem;

  @override
  State<LoadItem> createState() => _LoadItemState();
}

class _LoadItemState extends State<LoadItem> {
  final TextEditingController _quantityController = TextEditingController();

  TextStyle fieldTextStyle = const TextStyle(fontSize: 18);
  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: "",
      labelStyle: const TextStyle(color: Colors.black),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      fillColor: const Color.fromARGB(255, 189, 235, 255),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration getDecoration(
      String label, String hintText, TextStyle textStyle) {
    return InputDecoration(
      labelText: label,
      labelStyle: textStyle,
      hintText: hintText,
      hintStyle: textStyle, // Apply the same style to the hint text
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> loadItem() async {
    final networkService = NetworkService();
    Map<String, dynamic> data = {
      "store_id": 1,
      "item_id": widget.findItem.itemId,
      "quantity": int.parse(_quantityController.text),
    };

    final response = await networkService.postWithAuth('/packer-load-item',
        additionalData: data);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final LoadItemResponse loadItemResponse =
          LoadItemResponse.fromJson(responseData);

      // Show success message in a dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text(
                'Item "${loadItemResponse.itemName}" loaded successfully with quantity ${loadItemResponse.quantity}.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ListenBarcodePage()),
                  ); // Go back to the previous page
                },
              ),
            ],
          );
        },
      );
    } else {
      // Show error message in a dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to load item. Please try again.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Just dismiss the dialog
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Load Item"),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              textAlign: TextAlign.center,
              readOnly: true,
              maxLines: 3,
              decoration: inputDecoration(""),
              controller: TextEditingController(text: widget.findItem.itemName),
            ),
            SizedBox(height: 15),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.center,
                    readOnly: true,
                    decoration: inputDecoration(""),
                    controller: TextEditingController(
                        text: widget.findItem.shelfVertical),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    readOnly: true,
                    textAlign: TextAlign.center,
                    decoration: inputDecoration(''),
                    controller: TextEditingController(
                        text: widget.findItem.shelfHorizontal.toString()),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 15,
            ),
            Row(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Greyish background
                    shape: BoxShape.circle, // Circular shape
                  ),
                  child: IconButton(
                    iconSize: 40, // Increased icon size
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      int currentValue =
                          int.tryParse(_quantityController.text) ?? 0;
                      if (currentValue > 0) {
                        setState(() {
                          currentValue--;
                          _quantityController.text = currentValue.toString();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: TextFormField(
                      style: const TextStyle(fontSize: 30),
                      textAlign: TextAlign
                          .center, // Center the text inside TextFormField
                      controller: _quantityController,
                      decoration: getDecoration(
                          'Quantity', 'Enter Quantity', fieldTextStyle),
                      keyboardType: TextInputType.number,
                      onSaved: (value) {},
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter quantity' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Greyish background
                    shape: BoxShape.circle, // Circular shape
                  ),
                  child: IconButton(
                    iconSize: 40, // Increased icon size
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      int currentValue =
                          int.tryParse(_quantityController.text) ?? 0;
                      setState(() {
                        currentValue++;
                        _quantityController.text = currentValue.toString();
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        child: ElevatedButton(
          child: Text(
            'Load Item',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 100, vertical: 10),
            primary: Colors.deepPurpleAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: () {
            loadItem();
          },
        ),
      ),
    );
  }
}

class LoadItemResponse {
  final String itemName;
  final int itemId;
  final int shelfHorizontal;
  final String shelfVertical;
  final int quantity;

  LoadItemResponse({
    required this.itemName,
    required this.itemId,
    required this.shelfHorizontal,
    required this.shelfVertical,
    required this.quantity,
  });

  factory LoadItemResponse.fromJson(Map<String, dynamic> json) {
    return LoadItemResponse(
      itemName: json['item_name'] as String,
      itemId: json['item_id'] as int,
      shelfHorizontal: json['shelf_horizontal'] as int,
      shelfVertical: json['shelf_vertical'] as String,
      quantity: json['quantity'] as int,
    );
  }
}
