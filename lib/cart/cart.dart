import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CartItem {
  final String productId;
  final String productName;
  final int price;
  int quantity;
  int stockQuantity;
  final String image;

  CartItem(
      {required this.productId,
      required this.productName,
      required this.price,
      required this.quantity,
      required this.stockQuantity,
      required this.image});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
        productId: json['id'].toString(),
        productName: json['name'],
        price: json['price'],
        quantity: json['quantity'],
        stockQuantity: json['stock_quantity'],
        image: json['image']);
  }
}

class Address {
  final String placeId;
  final String mainText;
  final String secondaryText;

  Address(
      {required this.placeId,
      required this.mainText,
      required this.secondaryText});

  bool isEmpty() {
    return (placeId.isEmpty && mainText.isEmpty && secondaryText.isEmpty);
  }
}

class ItemInCart {
  final bool flag;
  final int quantity;

  ItemInCart(this.flag, this.quantity);
}

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  int _deliveryPartnerTip = 0;
  int _packagingFee = 15;
  int _deliveryFee = 35;
  Address _deliveryAddress =
      Address(placeId: "", mainText: "", secondaryText: "");

  CartModel() {
    final url = Uri.parse(
        'http://localhost:3000/cart-item'); // Replace with your server URL
    final headers = <String, String>{
      'Content-Type': 'application/json',
      // Add any other headers you need
    };
    final body = <String, dynamic>{
      'cart_id': 1,
      'items': true,
      // Add any other parameters you need
    };

    http.post(url, headers: headers, body: jsonEncode(body)).then((response) {
      if (response.statusCode == 200) {
        //final responseData = jsonDecode(response.body);
        final List<dynamic> jsonData = json.decode(response.body);
        final List<CartItem> items =
            jsonData.map((item) => CartItem.fromJson(item)).toList();

        _items.clear();
        _items.addAll(items);
        notifyListeners();
      } else {
        print(
            'HTTP POST request failed with status code ${response.statusCode}');
      }
    }).catchError((error) {
      print('HTTP POST request error: $error');
    });
  }
  List<CartItem> get items => _items;

  int get numberOfItems =>
      items.fold(0, (total, current) => total + current.quantity);

  int get totalPriceItems => items.fold(
      0, (total, current) => total + current.price * current.quantity);

  int get totalPrice =>
      totalPriceItems + _deliveryPartnerTip + _deliveryFee + _packagingFee;

  int get deliveryPartnerTip => _deliveryPartnerTip;

  set deliveryPartnerTip(int tip) {
    _deliveryPartnerTip = tip;
    notifyListeners();
  }

  int get packagingFee => _packagingFee;

  set packagingFee(int fee) {
    _packagingFee = fee;
    notifyListeners();
  }

  int get deliveryFee => _deliveryFee;

  set deliveryFee(int fee) {
    _deliveryFee = fee;
    notifyListeners();
  }

  Address get deliveryAddress => _deliveryAddress;

  set deliveryAddress(Address address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void addItemToCart(CartItem item) {
    print("Add Item To Cart");
    final url = Uri.parse(
        'http://localhost:3000/cart-item'); // Replace with your server URL
    final headers = <String, String>{
      'Content-Type': 'application/json',
      // Add any other headers you need
    };
    final body = <String, dynamic>{
      'cart_id': 1,
      'item_id': int.parse(item.productId),
      'quantity': 1,
      // Add any other parameters you need
    };

    http.post(url, headers: headers, body: jsonEncode(body)).then((response) {
      //print('HTTP POST response body: ${response.body}');
      if (response.statusCode == 200) {
        //final responseData = jsonDecode(response.body);
        final List<dynamic> jsonData = json.decode(response.body);
        final List<CartItem> items =
            jsonData.map((item) => CartItem.fromJson(item)).toList();

        _items.clear();
        _items.addAll(items);
        notifyListeners();
      } else {
        print(
            'HTTP POST request failed with status code ${response.statusCode}');
      }
    }).catchError((error) {
      print('HTTP POST request error: $error');
    });
  }

  void removeItem({required String itemId}) {
    print("Remove Item From Cart");
    final url = Uri.parse(
        'http://localhost:3000/cart-item'); // Replace with your server URL
    final headers = <String, String>{
      'Content-Type': 'application/json',
      // Add any other headers you need
    };
    final body = <String, dynamic>{
      'cart_id': 1,
      'item_id': int.parse(itemId),
      'quantity': -1,
      // Add any other parameters you need
    };

    http.post(url, headers: headers, body: jsonEncode(body)).then((response) {
      //print('HTTP POST response body: ${response.body}');
      if (response.statusCode == 200) {
        //final responseData = jsonDecode(response.body);
        final List<dynamic> jsonData = json.decode(response.body);
        final List<CartItem> items =
            jsonData.map((item) => CartItem.fromJson(item)).toList();

        _items.clear();
        _items.addAll(items);
        notifyListeners();
      } else {
        print(
            'HTTP POST request failed with status code ${response.statusCode}');
      }
    }).catchError((error) {
      print('HTTP POST request error: $error');
    });
  }

  bool isEmpty() {
    return _items.isEmpty;
  }

  void printItems(List<CartItem> items) {
    for (var item in _items) {
      print("Item Id {${item.productId}}");
      print("Item Name ${item.productName}");
    }
  }
}
