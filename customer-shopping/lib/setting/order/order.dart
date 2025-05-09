import 'dart:convert';

import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pronto/home/home_screen.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pronto/setting/order/order_detail.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/network/service.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
    // Fetch orders when the widget is initialized
    fetchOrders();
  }

  // Function to fetch orders based on customer ID
  Future<void> fetchOrders() async {
    const storage = FlutterSecureStorage();
    String? customerId = await storage.read(key: 'customerId');

    if (customerId == null) {
      print('Customer ID is null');
      return;
    }

    try {
      final Map<String, dynamic> body = {"customer_id": int.parse(customerId)};

      final networkService = NetworkService();
      final response = await networkService.postWithAuth('/sales-order',
          additionalData: body);

      if (response.statusCode == 200) {
        //print("FetchOrder Response: ${response.body}");
        List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          print('No orders found');
          return;
        }

        setState(() {
          orders = data.map((orderData) => Order.fromJson(orderData)).toList();
        });
      } else {
        print(
            'Failed to fetch orders: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurpleAccent,
        title: InkWell(
          child: ShaderMask(
            shaderCallback: (bounds) => const RadialGradient(
              center: Alignment.topLeft,
              radius: 1.0,
              colors: [Colors.white, Colors.white70],
              tileMode: TileMode.mirror,
            ).createShader(bounds),
            child: const Text(
              'Orders',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                // Remove 'UTC' and handle the date string properly
                String dateString = orders[index].date!.replaceAll(' UTC', '');
                DateTime orderDateTime = DateTime.parse(dateString).toLocal();
                String formattedDateTime =
                    DateFormat('MMMM d, y \'at\' h:mma').format(orderDateTime);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailPage(
                          salesOrderId: orders[index].id!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.18,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.withOpacity(0.4),
                          width: 1.0,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orders[index].address!,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                          Text(
                            formattedDateTime,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Icon(
                                Icons.info_outlined,
                                size: 14,
                                color: Colors.deepPurpleAccent,
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Order {
  int? id;
  String? date;
  String? address;
  String? paymentType;
  bool? paid;

  Order({this.id, this.date, this.address, this.paymentType, this.paid});

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['order_id'],
      date: json['order_date']?.toString() ?? 'N/A',
      address: json['order_address']?.toString() ?? 'N/A',
      paymentType: json['payment_type']?.toString() ?? 'N/A',
      paid: json['paid_status'] ?? false,
    );
  }
}
