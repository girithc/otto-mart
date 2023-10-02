import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pronto/utils/constants.dart';

class CustomerApiClient {
  CustomerApiClient(this.phone);

  final String phone; // Assuming phone is an integer

  Future<Customer> loginCustomer() async {
    final Map<String, dynamic> requestData = {
      "phone": int.parse(phone),
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
      final Customer customer = Customer.fromJson(responseBody);
      return customer;
    } else {
      throw Exception('Failed to login Customer');
    }
  }
}

class Customer {
  final int id;
  final String name;
  final int phone;
  final String address;
  final String createdAt;
  final int cartId;
  final int storeId;

  Customer(
      {required this.id,
      required this.name,
      required this.phone,
      required this.address,
      required this.createdAt,
      required this.cartId,
      required this.storeId});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        address: json['address'],
        createdAt: json['created_at'],
        cartId: json['cart_id'],
        storeId: json['store_id']);
  }
}
