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
  final bool outOfStock;

  CartDetails(
      {required this.cartId,
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
      required this.outOfStock});

  factory CartDetails.fromJson(Map<String, dynamic> json) {
    return CartDetails(
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
        outOfStock: json['out_of_stock']);
  }
}

class ItemInCart {
  final bool flag;
  final int quantity;

  ItemInCart(this.flag, this.quantity);
}

class CartModel extends ChangeNotifier {
  final List<CartItem> itemList = [];
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
        outOfStock: false);

    _fetchDefaultAddress();
    _fetchCartId().then((_) {
      _fetchCartItems(); // Then fetch cart items from the server
    });
  }

  void clearCart() {
    itemList.clear();
    //_fetchDefaultAddress();
    //_fetchCartId().then((_) {
    //  _fetchCartItems(); // Then fetch cart items from the server
    //});
  }

  Future<void> _fetchCartId() async {
    cartId = await storage.read(key: 'cartId');
    //print("cart Id $cartId");
    // You should handle cases where cartId is null!
    if (cartId == null) {
      // Handle it according to your requirements.
      // Maybe set a default value, or log an error.
      _logger.e('cartId is not found in the storage');
    } else {
      print("Fetched Cart Id $cartId");
    }
  }

  Future<void> _fetchCartItems() async {
    print("Fetch Cart Items");
    final customerId = await storage.read(key: 'customerId');
    final cartId = await storage.read(key: 'cartId');

    final body = <String, dynamic>{
      'customer_id': int.parse(customerId!),
      'cart_id': int.parse(cartId!),
    };

    //http.post(url, headers: headers, body: jsonEncode(body)).then((response)
    _networkService
        .postWithAuth('/cart-item', additionalData: body)
        .then((response) {
      //_logger.e('Response Fetch Cart Items: ${response.body}');
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

          itemList.clear();
          itemList.addAll(items);
          notifyListeners();
        } else {
          print("Response: $response");
          print("Empty Response");
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

  List<CartItem> get items => itemList;

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

  Future<OutOfStock?> addItemToCart(CartItem item) async {
    // Create an instance of NetworkService
    final networkService = NetworkService();

    String? cartID = await storage.read(key: 'cartId');
    String? customerId = await storage.read(key: 'customerId');

    if (item.quantity > 0) {
      item.quantity = 1;
    } else if (item.quantity < 0) {
      item.quantity = -1;
    } else {
      item.quantity = 0;
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
      print("Response Status Code ${response.statusCode}");
      print("Response Body ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final Map<String, dynamic> cartDetailsData =
            jsonData['cart_details'] as Map<String, dynamic>;
        _cartDetails = CartDetails.fromJson(cartDetailsData);

        final OutOfStock outOfStock = OutOfStock(
            productId: _cartDetails!.itemId,
            stockQuantity: _cartDetails!.quantity,
            outOfStock: _cartDetails!.outOfStock);

        if (_cartDetails?.cartId.toString() != cartID) {
          storage.write(key: 'cartId', value: _cartDetails?.cartId.toString());
        }
        final List<dynamic> cartItemsList = jsonData['cart_items_list'];
        final List<CartItem> items =
            cartItemsList.map((item) => CartItem.fromJson(item)).toList();

        print("Cart Items List $items");

        itemList.clear();
        itemList.addAll(items);
        notifyListeners();

        return outOfStock;
      } else {
        // Log or handle the error
        print("Error: ${response.statusCode} ${response.body}");
      }
    }).catchError((error) {
      // Handle any errors
      _logger.e('HTTP POST request error: $error');
    });

    cartID = await storage.read(key: 'cartId');
    customerId = await storage.read(key: 'customerId');

    print("After Add Item To Cart");
    print("Cart Id $cartID");
    print("Customer Id $customerId");
    return null;
  }

  bool isEmpty() {
    return itemList.isEmpty;
  }

  void printItems(List<CartItem> items) {
    for (var item in itemList) {
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

class OutOfStock {
  final int productId;
  final int stockQuantity;
  final bool outOfStock;

  OutOfStock(
      {required this.outOfStock,
      required this.productId,
      required this.stockQuantity});
}
