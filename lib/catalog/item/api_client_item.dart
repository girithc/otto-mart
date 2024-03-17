import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pronto/utils/constants.dart';

class ItemApiClient {
  ItemApiClient();

  Future<List<Item>> fetchItems(int categoryId, int storeId) async {
    var url = Uri.parse('$baseUrl/item');

    if (categoryId == 0 || storeId == 0) {
      throw Exception('fetchItems parameters are not valid');
    }

    var queryParams = {
      'category_id': categoryId.toString(),
      'store_id': storeId.toString()
    };

    url = url.replace(queryParameters: queryParams);

    //print("Query Params $queryParams");
    http.Response response = await http.get(url);

    print("Query Params $queryParams");
    print("Response Item: ${response.statusCode} ${response.body} ");

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Item> items =
          jsonData.map((item) => Item.fromJson(item)).toList();
      //print("Items Length ${items.length} First Item: ${items[0].name}");
      return items;
    } else {
      throw Exception('(ItemApiClient) Failed to load items');
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
  final List<String> image; // This should be a list of strings
  final int quantity;
  final String unitOfQuantity;
  final String brand;

  Item({
    required this.id,
    required this.name,
    required this.mrpPrice,
    required this.discount,
    required this.storePrice,
    required this.stockQuantity,
    required this.image, // Ensure this is passed as a List<String>
    required this.quantity,
    required this.unitOfQuantity,
    required this.brand,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    // Convert the image field to a List<String>, handling null and single string cases
    print('id: ${json['id']}, Type: ${json['id'].runtimeType}');
    print(
        'mrp_price: ${json['mrp_price']}, Type: ${json['mrp_price'].runtimeType}');
    print(
        'discount: ${json['discount']}, Type: ${json['discount'].runtimeType}');
    print(
        'store_price: ${json['store_price']}, Type: ${json['store_price'].runtimeType}');
    print(
        'stock_quantity: ${json['stock_quantity']}, Type: ${json['stock_quantity'].runtimeType}');
    print(
        'quantity: ${json['quantity']}, Type: ${json['quantity'].runtimeType}');

    List<String> images = [''];
    var imageField = json['image'];
    if (imageField != null) {
      if (imageField is List) {
        images = List<String>.from(imageField);
      } else if (imageField is String) {
        images = [imageField];
      }
    }

    return Item(
      id: json['id'],
      name: json['name'],
      mrpPrice: json['mrp_price'],
      discount: json['discount'],
      storePrice: json['store_price'],
      stockQuantity: json['stock_quantity'],
      image: images, // Pass the processed list of images
      quantity: json['quantity'],
      unitOfQuantity: json['unit_of_quantity'],
      brand: json['brand'],
    );
  }
}
