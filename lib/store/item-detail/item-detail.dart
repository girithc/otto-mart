import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:packer/pack/checklist.dart';
import 'package:packer/utils/constants.dart';
import 'package:packer/utils/network/service.dart';

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
      throw Exception('Failed to load items ${response.body}');
    }
  }

  Future<Item> addBarcode(int itemId, String barcode) async {
    var url = Uri.parse('$baseUrl/item-update');

    if (itemId == 0) {
      throw Exception('Invalid parameters');
    }
    if (barcode.isEmpty) {
      print('Setting Empty Barcode');
    }

    Map<String, String> headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> body = {
      'item_id': itemId,
      'barcode': barcode,
    };

    final networkService = NetworkService();
    final response =
        await networkService.postWithAuth('/item-update', additionalData: body);

    if (response.statusCode == 200) {
      final dynamic jsonData = json.decode(response.body);
      final Item item = Item.fromJson(jsonData);

      print("Item Updated: ${item.name}");
      return item;
    } else {
      throw Exception('Failed to update item');
    }
  }

  Future<ItemTruncated> fetchItemFromBarcode(String barcode) async {
    var url = Uri.parse('$baseUrl/item');

    if (barcode.isEmpty) {
      throw Exception('(ItemDetailApiClient) Parameters are not valid');
    }

    var queryParams = {
      'barcode': barcode,
    };
    url = url.replace(queryParameters: queryParams);

    print("Query Params $queryParams");
    http.Response response = await http.get(url);

    if (response.statusCode == 200) {
      final dynamic jsonData = json.decode(response.body);
      final ItemTruncated item = ItemTruncated.fromJson(jsonData);

      print("Item: ${item.name}");
      return item;
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<AllocationInfo> orderAssignSpace(String vertical, int horizontal,
      String packerPhone, int orderId, String storeId, String image) async {
    //var url = Uri.parse('$baseUrl/packer-space-order');
    final Map<String, dynamic> requestData = {
      "store_id": int.parse(storeId),
      "vertical": vertical,
      "horizontal": horizontal,
      "packer_phone": packerPhone,
      "sales_order_id": orderId,
      "image_url": image
      //"image": image
    };
    //rint('Uploaded Image: $image');

    final networkService = NetworkService();
    final response = await networkService.postWithAuth('/packer-space-order',
        additionalData: requestData);

    print("Response: ${response.body} ${response.statusCode}");

    if (response.statusCode == 200) {
      print("Packer Item $response");
      final jsonData = json.decode(response.body);
      return AllocationInfo.fromJson(jsonData);
    } else {
      throw Exception('Failed to load items ${response.body}');
    }
  }

  Future<PackerItemResponse> fetchItemFromBarcodeInSalesOrder(
      String barcode, int orderId, String storeId) async {
    const storage = FlutterSecureStorage();
    final phone = await storage.read(key: 'phone');

    final Map<String, dynamic> requestData = {
      "store_id": int.parse(storeId),
      "barcode": barcode,
      "packer_phone": phone,
      "sales_order_id": orderId
    };

    final networkService = NetworkService();
    final response = await networkService.postWithAuth('/packer-pack-item',
        additionalData: requestData);

    if (response.statusCode == 200) {
      print("Packer Item ${response.body}");
      final jsonData = json.decode(response.body);
      final PackerItemResponse packerItemResponse =
          PackerItemResponse.fromJson(jsonData);

      return packerItemResponse;
    } else {
      throw Exception('Failed to load items ${response.body}');
    }
  }

  Future<void> scanItemFromOrder(String barcode) async {}

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
  final String barcode;

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
      required this.categories,
      required this.barcode});

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
        barcode: json['barcode'] as String);
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
      'barcode': barcode
    };
  }
}

class ItemTruncated {
  final int id;
  final String name;
  final int mrpPrice;
  final String unitOfQuantity;
  final int quantity;
  int? stockQuantity;
  final List<String> imageURLs;

  ItemTruncated(
      {required this.id,
      required this.name,
      required this.mrpPrice,
      required this.unitOfQuantity,
      required this.quantity,
      required this.imageURLs,
      this.stockQuantity});

  factory ItemTruncated.fromJson(Map<String, dynamic> json) {
    return ItemTruncated(
        id: json['id'] as int,
        name: json['name'] as String,
        mrpPrice: json['mrp_price'] as int,
        unitOfQuantity: json['unit_of_quantity'] as String,
        quantity: json['quantity'] as int,
        imageURLs: List<String>.from(json['images']),
        stockQuantity: json['stock_quantity']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mrp_price': mrpPrice,
      'unit_of_quantity': unitOfQuantity,
      'quantity': quantity,
      'images': imageURLs,
    };
  }
}

class ItemPackOrder {
  final int id;
  final String name;
  final int mrpPrice;
  final String unitOfQuantity;
  final int quantity;
  final List<String> imageURLs;
  final int stockQuantity;

  ItemPackOrder({
    required this.id,
    required this.name,
    required this.mrpPrice,
    required this.unitOfQuantity,
    required this.quantity,
    required this.imageURLs,
    required this.stockQuantity,
  });

  factory ItemPackOrder.fromJson(Map<String, dynamic> json) {
    return ItemPackOrder(
        id: json['id'] as int,
        name: json['name'] as String,
        mrpPrice: json['mrp_price'] as int,
        unitOfQuantity: json['unit_of_quantity'] as String,
        quantity: json['quantity'] as int,
        imageURLs: List<String>.from(json['images']),
        stockQuantity: json['stock_quantity']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mrp_price': mrpPrice,
      'unit_of_quantity': unitOfQuantity,
      'quantity': quantity,
      'images': imageURLs,
      'stock_quantity': stockQuantity,
    };
  }
}

class AllocationInfo {
  final int salesOrderId;
  final int horizontal;
  final String vertical;
  final int shelfId;
  final String image;

  AllocationInfo(
      {required this.salesOrderId,
      required this.horizontal,
      required this.vertical,
      required this.shelfId,
      required this.image});

  factory AllocationInfo.fromJson(Map<String, dynamic> json) {
    return AllocationInfo(
        salesOrderId: json['sales_order_id'],
        horizontal: json['horizontal'],
        vertical: json['vertical'],
        shelfId: json['shelf_id'],
        image: json['image']);
  }
}
