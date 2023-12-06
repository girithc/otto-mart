import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:master/utils/constants.dart';

class ItemDetailApiClient {
  ItemDetailApiClient();

  Future<Item> fetchItem(int itemId) async {
    var url = Uri.parse('$baseUrl/item');

    if (itemId == 0) {
      throw Exception('(ItemDetailApiClient) Parameters are not valid');
    }

    var queryParams = {
      'item_id': itemId.toString(),
    };
    url = url.replace(queryParameters: queryParams);

    print("Query Params $queryParams");
    http.Response response = await http.get(url);

    if (response.statusCode == 200) {
      final dynamic jsonData = json.decode(response.body);
      final Item item = Item.fromJson(jsonData);

      print("Item: ${item.name}");
      return item;
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<Item> editItem(Item item) async {
    var url = Uri.parse(
        '$baseUrl/item'); // Assuming the endpoint expects the ID in the URL

    if (item.id == 0) {
      throw Exception('(ItemDetailApiClient) Parameters are not valid');
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    print("Debug Item Before Send off ${item.name}");

    final itemJson =
        item.toJson(); // Assuming you have a toJson method in your Item class

    http.Response response = await http.put(
      url,
      headers: headers,
      body: json.encode(itemJson),
    );

    if (response.statusCode == 200) {
      final dynamic jsonData = json.decode(response.body);
      final Item updatedItem = Item.fromJson(jsonData);

      print("Updated Item: ${updatedItem.name}");
      return updatedItem;
    } else {
      throw Exception('Failed to update item');
    }
  }
}

class Item {
  final int id;
  final String name;
  final int mrpPrice;
  final int discount;
  final int storePrice;
  final int stockQuantity;
  final List<String> images;
  final int quantity;
  final String unitOfQuantity;
  final List<String> categories;

  Item(
      {required this.id,
      required this.name,
      required this.mrpPrice,
      required this.discount,
      required this.storePrice,
      required this.stockQuantity,
      required this.images,
      required this.quantity,
      required this.unitOfQuantity,
      required this.categories});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      name: json['name'] as String,
      mrpPrice: json['mrp_price'] as int,
      discount: json['discount'] as int,
      storePrice: json['store_price'] as int,
      stockQuantity: json['stock_quantity'] as int,
      images: List<String>.from(json['images']),
      quantity: json['quantity'] as int,
      unitOfQuantity: json['unit_of_quantity'] as String,
      categories: List<String>.from(json['categories']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mrpPrice': mrpPrice,
      'discount': discount,
      'storePrice': storePrice,
      'stockQuantity': stockQuantity,
      'images': images,
      'quantity': quantity,
      'unitOfQuantity': unitOfQuantity,
      'categories': categories,
    };
  }
}
