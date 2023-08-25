import 'dart:convert';

import 'package:http/http.dart' as http;

class SearchItemApiClient {
  final String baseUrl;

  SearchItemApiClient(this.baseUrl);

  Future<List<Item>> fetchItems(int categoryId, int storeId) async {
    var url = Uri.parse('http://localhost:3000/search-item');

    if (categoryId == 0 || storeId == 0) {
      throw Exception('(ItemApiClient) Parameters are not valid');
    }

    var queryParams = {
      'category_id': categoryId.toString(),
      'store_id': storeId.toString()
    };
    url = url.replace(queryParameters: queryParams);

    print("Query Params $queryParams");
    http.Response response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Item> items =
          jsonData.map((item) => Item.fromJson(item)).toList();
      print("Items Length ${items.length} First Item: ${items[0].name}");
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

  Item(
      {required this.id,
      required this.name,
      required this.price,
      required this.stockQuantity});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        stockQuantity: json['stock_quantity']);
  }
}
