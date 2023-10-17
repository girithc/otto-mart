import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:pronto/utils/constants.dart';

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
  late String customerId;

  // Initialize storage
  final storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  // Other variables
  String? cartId;

  Address _deliveryAddress = Address(
      id: 0,
      lineOne: "",
      lineTwo: "",
      city: '',
      state: '',
      streetAddress: '',
      zip: '',
      createdAt: DateTime(2020),
      customerId: 0,
      longitude: 0.00,
      latitude: 0.0);

  CartModel(this.customerId) {
    _fetchCartId().then((_) {
      _fetchCartItems(); // Then fetch cart items from the server
    });
  }

  Future<void> _fetchCartId() async {
    cartId = await storage.read(key: 'cartId');
    print("cart Id $cartId");
    // You should handle cases where cartId is null!
    if (cartId == null) {
      // Handle it according to your requirements.
      // Maybe set a default value, or log an error.
      _logger.e('cartId is not found in the storage');
    }
  }

  void _fetchCartItems() {
    final url = Uri.parse('$baseUrl/cart-item');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    //print("customer Id $customerId");

    int? parsedCustomerId;
    try {
      parsedCustomerId = int.parse(customerId);
    } catch (e) {
      _logger.e('Failed to parse customerId: $customerId, error: $e ');
    }

    print("customer Id $parsedCustomerId");

    if (parsedCustomerId == null) return;

    final body = <String, dynamic>{
      'customer_id': parsedCustomerId,
    };

    http.post(url, headers: headers, body: jsonEncode(body)).then((response) {
      //_logger.e('Response: $response');
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final List<dynamic> jsonData = json.decode(response.body);
          final List<CartItem> items =
              jsonData.map((item) => CartItem.fromJson(item)).toList();

          _items.clear();
          _items.addAll(items);
          notifyListeners();
        } else {
          _logger.e('Empty response received from server');
        }
      } else {
        _logger.e(
            'HTTP POST request failed with status code ${response.statusCode}');
      }
    }).catchError((error) {
      _logger.e('(cart model) HTTP POST request error: $error');
    });
  }

  Future<bool> postDeliveryAddress(
      String flatBuildingName,
      String lineOne,
      String lineTwo,
      String? city,
      String? zipCode,
      String? state,
      double latitude,
      double longitude) async {
    final url = Uri.parse('$baseUrl/address');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    int? parsedCustomerId;
    try {
      parsedCustomerId = int.parse(customerId);
    } catch (e) {
      _logger.e('Failed to parse customerId: $customerId, error: $e');
      return false; // if we can't parse customerId, it makes sense to return early
    }

    final body = <String, dynamic>{
      'customer_id': parsedCustomerId,
      'street_address': flatBuildingName,
      'line_one': lineOne,
      'line_two': lineTwo,
      'city': city,
      'state': state,
      'zip': zipCode,
      'latitude': latitude,
      'longitude': longitude
    };

    try {
      final response =
          await http.post(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final data = json.decode(response.body);
          Address address = Address.fromJson(data);
          _deliveryAddress = address;
          notifyListeners();
          return true;
        } else {
          _logger.e('Empty response received from server');
          return false;
        }
      } else {
        _logger.e(
            'HTTP POST request failed with status code ${response.statusCode}');
        return false;
      }
    } catch (error) {
      _logger.e('(cart model (address)) HTTP POST request error: $error');
      return false;
    }
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

  Future<Address> postAddress() async {
    final Map<String, dynamic> requestData = {
      //"phone": int.parse(phone),
    };

    final http.Response response = await http.post(
      Uri.parse('$baseUrl/customer'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final Address addr = Address.fromJson(responseBody);
      return addr;
    } else {
      throw Exception('Failed to login Customer');
    }
  }

  void addItemToCart(CartItem item) {
    //print("Add Item To Cart: $cartId");
    final url = Uri.parse('$baseUrl/cart-item'); // Replace with your server URL
    final headers = <String, String>{
      'Content-Type': 'application/json',
      // Add any other headers you need
    };

    print('CartId $cartId');
    print('ProductId ${item.productId}');
    final body = <String, dynamic>{
      'cart_id': int.parse(cartId!),
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
        _logger.e(
            'HTTP POST request failed with status code ${response.statusCode}');
      }
    }).catchError((error) {
      _logger.e('HTTP POST request error: $error');
    });
  }

  void removeItem({required String itemId}) {
    //print("Remove Item From Cart");
    final url = Uri.parse('$baseUrl/cart-item'); // Replace with your server URL
    final headers = <String, String>{
      'Content-Type': 'application/json',
      // Add any other headers you need
    };
    final body = <String, dynamic>{
      'cart_id': int.parse(cartId!),
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
        _logger.e(
            'HTTP POST request failed with status code ${response.statusCode}');
      }
    }).catchError((error) {
      _logger.e('HTTP POST request error: $error');
    });
  }

  bool isEmpty() {
    return _items.isEmpty;
  }

  void printItems(List<CartItem> items) {
    for (var item in _items) {
      _logger.e("Item Id {${item.productId}}");
      _logger.e("Item Name ${item.productName}");
    }
  }
}

class Address {
  final int id;
  final int customerId;
  final String streetAddress;
  final String lineOne;
  final String lineTwo;
  final String city;
  final String state;
  final String zip;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.customerId,
    required this.streetAddress,
    required this.lineOne,
    required this.lineTwo,
    required this.city,
    required this.state,
    required this.zip,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      customerId: json['customer_id'],
      streetAddress: json['street_address'],
      lineOne: json['line_one'],
      lineTwo: json['line_two'],
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool isEmpty() {
    return (streetAddress.isEmpty && lineOne.isEmpty && lineTwo.isEmpty);
  }
}

class AddressModel extends ChangeNotifier {
  final List<Address> addrs = [];
  final String customerId;
  final Logger _logger = Logger();

  AddressModel(this.customerId);

  void fetchAddresses() {
    final url = Uri.parse('$baseUrl/address');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    int? parsedCustomerId;
    try {
      parsedCustomerId = int.parse(customerId);
    } catch (e) {
      _logger.e('Failed to parse customerId: $customerId, error: $e ');
    }

    if (parsedCustomerId == null) return;

    final body = <String, dynamic>{
      'customer_id': parsedCustomerId,
    };

    http.post(url, headers: headers, body: jsonEncode(body)).then((response) {
      //_logger.e('Response: $response');
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final List<dynamic> jsonData = json.decode(response.body);
          final List<Address> addresses =
              jsonData.map((address) => Address.fromJson(address)).toList();

          addrs.clear();
          addrs.addAll(addresses);
          notifyListeners();
        } else {
          _logger.e('Empty response received from server');
        }
      } else {
        _logger.e(
            'HTTP POST request failed with status code ${response.statusCode}');
      }
    }).catchError((error) {
      _logger.e('(cart model) HTTP POST request error: $error');
    });
  }

  // adds addresss to profile
  // sets address to default
  void addAddress() {
    final url = Uri.parse('$baseUrl/address');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    int? parsedCustomerId;
    try {
      parsedCustomerId = int.parse(customerId);
    } catch (e) {
      _logger.e('Failed to parse customerId: $customerId, error: $e ');
    }

    if (parsedCustomerId == null) return;

    final body = <String, dynamic>{
      'customer_id': parsedCustomerId,
    };

    http.post(url, headers: headers, body: jsonEncode(body)).then((response) {
      //_logger.e('Response: $response');
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final List<dynamic> jsonData = json.decode(response.body);
          final List<Address> addresses =
              jsonData.map((address) => Address.fromJson(address)).toList();

          addrs.clear();
          addrs.addAll(addresses);
          notifyListeners();
        } else {
          _logger.e('Empty response received from server');
        }
      } else {
        _logger.e(
            'HTTP POST request failed with status code ${response.statusCode}');
      }
    }).catchError((error) {
      _logger.e('(cart model) HTTP POST request error: $error');
    });
  }
}
