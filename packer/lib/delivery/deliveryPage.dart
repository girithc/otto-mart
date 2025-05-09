import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:packer/main.dart';
import 'package:packer/utils/network/service.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  TextEditingController otpController = TextEditingController();
  bool isOTPEntered = false;
  String phone = '';
  String location = '';
  String orderPlacedTime = '';
  final storage = new FlutterSecureStorage();
  final networkService = NetworkService();
  bool isPacked = false;
  GetOrderResponse?
      orderInfo; // Use the GetOrderResponse class to store order info

  Future<void> completeOrder() async {
    Map<String, dynamic> body = {
      'cart_id': orderInfo!.cartId,
      'customer_phone': orderInfo!.phone,
    };

    final response = await networkService.postWithAuth(
      '/packer-complete-order', // Replace with your actual endpoint
      additionalData: body,
    );

    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      // Parse the JSON response and create a GetOrderResponse instance
      final jsonResponse = jsonDecode(response.body);
      bool success = false;
      setState(() {
        success = jsonResponse['success'];
      });

      if (!success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Order Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phone: ${orderInfo!.phone}'),
                Text('Location: ${orderInfo!.location}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                  // Navigate to HomePage
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Order Completed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phone: ${orderInfo!.phone}'),
                Text('Location: ${orderInfo!.location}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              MyHomePage())); // Navigate to HomePage
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      // Handle the error case
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Order Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone: ${orderInfo!.phone}'),
              Text('Location: ${orderInfo!.location}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
                // Navigate to HomePage
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> fetchOrderInfo() async {
    final storeId = await storage.read(key: 'storeId');

    Map<String, dynamic> body = {
      'otp': otpController.text,
      'store_id': 1,
    };

    final response = await networkService.postWithAuth(
      '/packer-get-order', // Replace with your actual endpoint
      additionalData: body,
    );

    print("Respone ${response.body}");
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      setState(() {
        orderInfo = GetOrderResponse.fromJson(jsonResponse);
        isOTPEntered =
            true; // Set isOTPEntered to true after successfully fetching the order info
      });
    } else {
      // Handle the error case by showing a dialog or updating the UI
      print('Failed to fetch order info. Status code: ${response.statusCode}');
      setState(() {
        isOTPEntered = false; // Reset the flag as no order info was fetched
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('No Order Found'),
            content:
                Text('Unable to fetch order information. Please try again.'),
            actions: <Widget>[
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              decoration: InputDecoration(
                labelText: 'OTP',
                suffixIcon: !isOTPEntered
                    ? Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.0,
                            vertical: 2), // Adjust padding as needed
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black, // Border color
                            width: 1.0, // Border width
                          ),
                          borderRadius:
                              BorderRadius.circular(25.0), // Border radius
                        ),
                        child: IconButton(
                          icon: Icon(Icons.check_outlined),
                          onPressed: () {
                            setState(() {
                              fetchOrderInfo();
                            });
                          },
                        ),
                      )
                    : null,
              ),
              readOnly: isOTPEntered,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            if (isOTPEntered) ...[
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(labelText: 'Location'),
                controller:
                    TextEditingController(text: orderInfo!.location.toString()),
                readOnly: true,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Phone'),
                controller: TextEditingController(text: orderInfo!.phone),
                readOnly: true,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Order Status'),
                controller: TextEditingController(
                    text: orderInfo!.orderStatus.toString()),
                readOnly: true,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Order Time'),
                controller: TextEditingController(
                    text: orderInfo!.orderTime.toString()),
                readOnly: true,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Active'),
                controller:
                    TextEditingController(text: orderInfo!.active.toString()),
                readOnly: true,
              ),
              SizedBox(height: 20),
              orderInfo!.orderStatus == 'packed'
                  ? ElevatedButton(
                      onPressed: completeOrder,
                      child: Text('Complete Order'),
                    )
                  : SizedBox.shrink()
            ],
          ],
        ),
      ),
    );
  }
}

// Define a Dart class that mirrors the GetOrder response structure
class GetOrderResponse {
  final int location;
  final bool active;
  final int cartId;
  final DateTime orderTime;
  final String phone;
  final String orderStatus;

  GetOrderResponse({
    required this.location,
    required this.active,
    required this.cartId,
    required this.orderTime,
    required this.phone,
    required this.orderStatus,
  });

  // Factory constructor to create a GetOrderResponse instance from a map
  factory GetOrderResponse.fromJson(Map<String, dynamic> json) {
    return GetOrderResponse(
      location: json['location'],
      active: json['active'],
      cartId: json['cart_id'],
      orderTime: DateTime.parse(json['order_time']),
      phone: json['phone'],
      orderStatus: json['order_status'],
    );
  }
}
