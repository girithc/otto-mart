import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pronto/utils/constants.dart';

class SearchItemApiClient {
  SearchItemApiClient();

  Future<List<Item>> fetchSearchItems(String queryString) async {
    var url = Uri.parse('$baseUrl/search-item');

    if (queryString.isEmpty) {
      throw Exception('(SearchItemApiClient) Parameters are not valid');
    }

    var requestBody = jsonEncode({
      'name': queryString,
    });

    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Item> items =
          jsonData.map((item) => Item.fromJson(item)).toList();
      //print("Items Length ${items.length} First Item: ${items[0].name}");
      return items;
    } else {
      throw Exception('Failed to load items');
    }
  }
}

class Item {
  final int id;
  final String name;
  final int price;
  final int stockQuantity;
  final String image;

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.stockQuantity,
    required this.image,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        stockQuantity: json['stock_quantity'],
        image: json['image']);
  }
}
