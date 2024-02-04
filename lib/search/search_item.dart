import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/network/service.dart';

class SearchItemApiClient {
  SearchItemApiClient();

  Future<List<Item>> fetchSearchItems(String queryString) async {
    var url = Uri.parse('$baseUrl/search-item');

    if (queryString.isEmpty) {
      throw Exception('(SearchItemApiClient) Parameters are not valid');
    }

    final Map<String, dynamic> body = {
      'name': queryString,
    };

    final networkService = NetworkService();
    final response =
        await networkService.postWithAuth('/search-item', additionalData: body);

    /*
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );
    */

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
  final int mrpPrice;
  final int discount;
  final int storePrice;
  final int stockQuantity;
  final String image;
  final int quantity;
  final String unitOfQuantity;
  final String brand;

  Item(
      {required this.id,
      required this.name,
      required this.mrpPrice,
      required this.discount,
      required this.storePrice,
      required this.stockQuantity,
      required this.image,
      required this.quantity,
      required this.unitOfQuantity,
      required this.brand});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      mrpPrice: json['mrp_price'],
      discount: json['discount'],
      storePrice: json['store_price'],
      stockQuantity: json['stock_quantity'],
      image: json['image'],
      quantity: json['quantity'],
      unitOfQuantity: json['unit_of_quantity'],
      brand: json['brand'],
    );
  }
}
