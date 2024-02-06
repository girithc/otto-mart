import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/network/service.dart';

class CartItem {
  final String productId;
  final String productName;
  final int price;
  final int soldPrice;
  int quantity;
  int stockQuantity;
  final String image;

  CartItem(
      {required this.productId,
      required this.productName,
      required this.price,
      required this.soldPrice,
      required this.quantity,
      required this.stockQuantity,
      required this.image});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
        productId: json['id'].toString(),
        productName: json['name'],
        price: json['price'],
        soldPrice: json['sold_price'],
        quantity: json['quantity'],
        stockQuantity: json['stock_quantity'],
        image: json['image']);
  }
}

class CartDetails {
  final int cartItemId;
  final int cartId;
  final int itemId;
  final int quantity;
  final int itemCost;
  final int deliveryFee;
  final int platformFee;
  final int smallOrderFee;
  final int rainFee;
  final int highTrafficSurcharge;
  final int packagingFee;
  final int peakTimeSurcharge;
  final int subtotal;
  final int discounts;

  CartDetails({
    required this.cartItemId,
    required this.cartId,
    required this.itemId,
    required this.quantity,
    required this.itemCost,
    required this.deliveryFee,
    required this.platformFee,
    required this.smallOrderFee,
    required this.rainFee,
    required this.highTrafficSurcharge,
    required this.packagingFee,
    required this.peakTimeSurcharge,
    required this.subtotal,
    required this.discounts,
  });

  factory CartDetails.fromJson(Map<String, dynamic> json) {
    return CartDetails(
      cartItemId: json['cart_item_id'],
      cartId: json['cart_id'],
      itemId: json['item_id'],
      quantity: json['quantity'],
      itemCost: json['item_cost'],
      deliveryFee: json['delivery_fee'],
      platformFee: json['platform_fee'],
      smallOrderFee: json['small_order_fee'],
      rainFee: json['rain_fee'],
      highTrafficSurcharge: json['high_traffic_surcharge'],
      packagingFee: json['packaging_fee'],
      peakTimeSurcharge: json['peak_time_surcharge'],
      subtotal: json['subtotal'],
      discounts: json['discounts'],
    );
  }
}

class ItemInCart {
  final bool flag;
  final int quantity;

  ItemInCart(this.flag, this.quantity);
}

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  final NetworkService _networkService = NetworkService();

  CartDetails? _cartDetails;
  int _deliveryPartnerTip = 0;

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
      streetAddress: "",
      zip: '',
      createdAt: DateTime(2020),
      customerId: 0,
      longitude: 0.00,
      latitude: 0.0);

  CartModel() {
    _cartDetails = CartDetails(
      cartItemId: 0,
      cartId: 0,
      itemId: 0,
      quantity: 0,
      itemCost: 0,
      deliveryFee: 0,
      platformFee: 0,
      smallOrderFee: 0,
      rainFee: 0,
      highTrafficSurcharge: 0,
      packagingFee: 0,
      peakTimeSurcharge: 0,
      subtotal: 0,
      discounts: 0,
    );

    _fetchDefaultAddress();
    _fetchCartId().then((_) {
      _fetchCartItems(); // Then fetch cart items from the server
    });
  }

  void clearCart() {
    _fetchDefaultAddress();
    _fetchCartId().then((_) {
      _fetchCartItems(); // Then fetch cart items from the server
    });
  }

  Future<void> _fetchCartId() async {
    cartId = await storage.read(key: 'cartId');
    //print("cart Id $cartId");
    // You should handle cases where cartId is null!
    if (cartId == null) {
      // Handle it according to your requirements.
      // Maybe set a default value, or log an error.
      _logger.e('cartId is not found in the storage');
    }
  }

  Future<void> _fetchCartItems() async {
    final url = Uri.parse('$baseUrl/cart-item');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final customerId = await storage.read(key: 'customerId');

    int? parsedCustomerId;
    try {
      parsedCustomerId = int.parse(customerId!);
    } catch (e) {
      _logger.e('Failed to parse customerId: $customerId, error: $e ');
    }

    if (parsedCustomerId == null) return;

    final body = <String, dynamic>{
      'customer_id': parsedCustomerId,
    };

    //http.post(url, headers: headers, body: jsonEncode(body)).then((response)
    _networkService
        .postWithAuth('/cart-item', additionalData: body)
        .then((response) {
      //_logger.e('Response: $response');
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final Map<String, dynamic> jsonData = json.decode(response.body);

          final Map<String, dynamic> cartDetailsData =
              jsonData['cart_details'] as Map<String, dynamic>;
          _cartDetails = CartDetails.fromJson(cartDetailsData);
          //print("Cart Details Data: $cartDetailsData");
          // Extracting 'cart_items_list' from the response
          final List<dynamic> cartItemsList = jsonData['cart_items_list'];
          final List<CartItem> items =
              cartItemsList.map((item) => CartItem.fromJson(item)).toList();

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

  Future<void> _fetchDefaultAddress() async {
    final customerId = await storage.read(key: 'customerId');

    final body = <String, dynamic>{
      'customer_id': int.parse(customerId!),
      "is_default": true,
    };

    _networkService
        .postWithAuth('/address', additionalData: body)
        .then((response) {
      //_logger.e('Response: $response');
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty && response.contentLength! > 3) {
          final List<dynamic> jsonData = json.decode(response.body);
          final List<Address> items =
              jsonData.map((item) => Address.fromJson(item)).toList();

          deliveryAddress = items[0];
          notifyListeners();
        } else {
          //print("Response  Empty");
          deliveryAddress.id = -1;
          notifyListeners();
        }
      } else {
        _logger.e(
            'HTTP POST request failed with status code ${response.statusCode}');
      }
    }).catchError((error) {
      if (error != null && error is http.ClientException) {
        // Handle the case where the response is null
        deliveryAddress.id = -1;
        _logger.e('null response');
      } else {
        _logger.e('(cart model) HTTP POST request error: $error');
      }
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
    const storage = FlutterSecureStorage();
    final phone = await storage.read(key: 'phone');

    if (phone == null) {
      _logger.e('Customer ID not found in Secure Storage');
      return false;
    }

    final url = Uri.parse('$baseUrl/address');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    print("Post Delivery $phone");

    final data = <String, dynamic>{
      'customer_id': phone,
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
      //final response = await http.post(url, headers: headers, body: jsonEncode(body));

      final response =
          await _networkService.postWithAuth('/address', additionalData: data);

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
            'HTTP POST request failed with status code ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (error) {
      _logger.e('(cart model (address)) HTTP POST request error: $error');
      return false;
    }
  }

  List<CartItem> get items => _items;

  int get numberOfItems => _cartDetails!.quantity;
  int get totalPriceItems => _cartDetails!.itemCost;
  int get totalPrice => _cartDetails!.subtotal;
  int get discount => _cartDetails!.discounts;
  int get platformFee => _cartDetails!.platformFee;
  int get packagingFee => _cartDetails!.packagingFee;
  int get deliveryFee => _cartDetails!.deliveryFee;
  int get smallOrderFee => _cartDetails!.smallOrderFee;

  int get deliveryPartnerTip => _deliveryPartnerTip;

  set deliveryPartnerTip(int tip) {
    _deliveryPartnerTip = tip;
    notifyListeners();
  }

  Address get deliveryAddress => _deliveryAddress;

  set deliveryAddress(Address address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  Future<void> addItemToCart(CartItem item) async {
    // Create an instance of NetworkService
    final networkService = NetworkService();

    String? cartID = await storage.read(key: 'cartId');
    String? customerId = await storage.read(key: 'customerId');

    print("Add Item To Cart");
    print("Cart Id $cartID");
    print("Customer Id $customerId");

    // Define the body for the POST request
    if (item.quantity > 0) {
      item.quantity = 1;
    } else {
      item.quantity = -1;
    }
    final Map<String, dynamic> body = {
      'cart_id': int.parse(cartID!),
      'item_id': int.parse(item.productId),
      'quantity': item.quantity,
      'customer_id': int.parse(customerId!)
      // Add any other parameters you need
    };

    // Use NetworkService to make the authenticated POST request
    networkService
        .postWithAuth('/cart-item', additionalData: body)
        .then((response) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final Map<String, dynamic> cartDetailsData =
            jsonData['cart_details'] as Map<String, dynamic>;
        _cartDetails = CartDetails.fromJson(cartDetailsData);

        if (_cartDetails?.cartId.toString() != cartID) {
          print("\n");
          print("Old Cart Id $cartID");
          print("New Cart Id ${_cartDetails?.cartId}");
          print("\n");
          storage.write(key: 'cartId', value: _cartDetails?.cartId.toString());
          _items.clear();
          clearCart();
        } else {
          final List<dynamic> cartItemsList = jsonData['cart_items_list'];
          final List<CartItem> items =
              cartItemsList.map((item) => CartItem.fromJson(item)).toList();

          _items.clear();
          _items.addAll(items);
          notifyListeners();
        }
      } else {
        // Log or handle the error
        _logger.e(
            'HTTP POST request failed with status code ${response.statusCode} ${response.body}');
      }
    }).catchError((error) {
      // Handle any errors
      _logger.e('HTTP POST request error: $error');
    });
  }

  Future<void> removeItem({required String itemId}) async {
    final networkService = NetworkService();

    //print("Remove Item From Cart");
    //final url = Uri.parse('$baseUrl/cart-item'); // Replace with your server URL
    //final headers = <String, String>{ 'Content-Type': 'application/json',};
    String? cartID = await storage.read(key: 'cartId');

    final body = <String, dynamic>{
      'cart_id': int.parse(cartID!),
      'item_id': int.parse(itemId),
      'quantity': -1,
      // Add any other parameters you need
    };

    //http.post(url, headers: headers, body: jsonEncode(body)).then((response)
    networkService
        .postWithAuth('/cart-item', additionalData: body)
        .then((response) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Extracting 'cart_details' from the response
        final Map<String, dynamic> cartDetailsData = jsonData['cart_details'];
        _cartDetails = CartDetails.fromJson(cartDetailsData);

        // Extracting 'cart_items_list' from the response
        final List<dynamic> cartItemsList = jsonData['cart_items_list'];
        final List<CartItem> items =
            cartItemsList.map((item) => CartItem.fromJson(item)).toList();

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
  int id;
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
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
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
  final _networkService = NetworkService();

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

    //http.post(url, headers: headers, body: jsonEncode(body)).then((response) {
    //_logger.e('Response: $response');
    _networkService
        .postWithAuth('/address', additionalData: body)
        .then((response) {
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

    //http.post(url, headers: headers, body: jsonEncode(body)).then((response) {
    //_logger.e('Response: $response');
    _networkService
        .postWithAuth('/address', additionalData: body)
        .then((response) {
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
