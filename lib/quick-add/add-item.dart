import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:master/utils/constants.dart';

class AddItemScreen extends StatefulWidget {
  final String barcode;

  AddItemScreen({Key? key, required this.barcode}) : super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late ItemAddQuick newItem;
  List<Category> categories = [];
  int? selectedCategoryId;
  String? selectedUnit;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    newItem =
        ItemAddQuick(barcode: widget.barcode, stockQuantity: 10, discount: 0);
    fetchCategories();
    fetchStoreId();
  }

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      var response = await createItem(newItem);
      if (response.success) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Item added successfully.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to add item.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> fetchCategories() async {
    const url = '$baseUrl/get-category';
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        categories = (json.decode(response.body) as List)
            .map((data) => Category.fromJson(data))
            .toList();
      });
    } else {
      print(response.body);
    }
  }

  Future<void> fetchStoreId() async {
    String? storeId = await secureStorage.read(key: 'storeId');
    if (storeId != null) {
      setState(() {
        newItem.storeId = int.tryParse(storeId) ?? 0;
      });
    }
  }

  Future<ItemAddQuickResponse> createItem(ItemAddQuick item) async {
    const url = '$baseUrl/item-add-quick';

    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(item.toJson()),
    );

    if (response.statusCode == 200) {
      return ItemAddQuickResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Item'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(5),
            child: Column(
              children: <Widget>[
                TextFormField(
                  initialValue: newItem.barcode,
                  decoration: InputDecoration(labelText: 'Barcode'),
                  onSaved: (value) => newItem.barcode = value!,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter barcode' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Name'),
                  onSaved: (value) => newItem.name = value!,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter name' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Brand Name'),
                  onSaved: (value) => newItem.brandName = value!,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter brand name' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) =>
                      newItem.quantity = int.tryParse(value!) ?? 0,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter quantity' : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  decoration: InputDecoration(labelText: 'Unit'),
                  items: <String>['g', 'mg', 'ml', 'l', 'kg', 'ct']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedUnit = newValue;
                    });
                  },
                  onSaved: (value) => newItem.unit = value ?? '',
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select a unit'
                      : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Description'),
                  onSaved: (value) => newItem.description = value!,
                ),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: categories.map((Category category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedCategoryId = newValue;
                      newItem.categoryId = newValue ?? 0;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'MRP Price'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) {
                    int parsedValue = int.tryParse(value!) ?? 0;
                    newItem.mrpPrice = parsedValue;
                    newItem.storePrice =
                        parsedValue; // Set storePrice same as mrpPrice
                  },
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter MRP price' : null,
                ),
                SizedBox(
                  height: 25,
                ),
                ElevatedButton(
                  onPressed: submitForm,
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ItemAddQuick {
  String name;
  String brandName;
  int quantity;
  String barcode;
  String unit;
  String description;
  int createdBy;
  int categoryId;
  int storeId;
  int mrpPrice;
  int storePrice;
  int discount;
  int stockQuantity;

  ItemAddQuick({
    this.name = '',
    this.brandName = '',
    this.quantity = 0,
    this.barcode = '',
    this.unit = '',
    this.description = '',
    this.createdBy = 0,
    this.categoryId = 0,
    this.storeId = 0,
    this.mrpPrice = 0,
    this.storePrice = 0,
    this.discount = 0,
    this.stockQuantity = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'brand_name': brandName,
        'quantity': quantity,
        'barcode': barcode,
        'unit': unit,
        'description': description,
        'created_by': createdBy,
        'category_id': categoryId,
        'store_id': storeId,
        'mrp_price': mrpPrice,
        'store_price': storePrice,
        'discount': discount,
        'stock_quantity': stockQuantity,
      };
}

class ItemAddQuickResponse {
  final bool success;

  ItemAddQuickResponse({required this.success});

  factory ItemAddQuickResponse.fromJson(Map<String, dynamic> json) {
    return ItemAddQuickResponse(
      success: json['success'] as bool,
    );
  }
}

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
