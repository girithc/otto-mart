import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pronto/home/home_screen.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pronto/setting/order/order_detail.dart';
import 'package:pronto/utils/constants.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<Order> orders = [];
  List<Order> orderSample = [];
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
      var headers = {'Content-Type': 'application/json'};
      var body = json.encode({"customer_id": int.parse(customerId)});
      var url = Uri.parse('$baseUrl/sales-order');

      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("FetchOrder Response: ${response.body}");
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MyHomePage(
                  title: 'Otto Mart',
                ),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Use a ListView.builder to dynamically create the order containers
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => OrderDetailPage(
                                salesOrderId: orders[index].id!,
                              )),
                    );
                  },
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.20,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: orders[index].paid!
                              ? Colors.indigoAccent.withOpacity(0.5)
                              : Colors.deepOrangeAccent.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Centers the column content
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Paid: ${orders[index].paid.toString()}',
                            style: GoogleFonts.robotoMono(fontSize: 18),
                          ),
                          Text(
                            orders[index].address!,
                            style: GoogleFonts.robotoMono(fontSize: 18),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign:
                                TextAlign.center, // Center-aligns the text
                          ),
                          Text(
                            orders[index].date!,
                            style: GoogleFonts.robotoMono(fontSize: 18),
                          ),
                          Text(
                            orders[index].paymentType!,
                            style: GoogleFonts.robotoMono(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Add more containers or widgets if needed
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
  String? deliveryPartnerName;
  bool? paid;

  Order(
      {this.id,
      this.date,
      this.address,
      this.paymentType,
      this.deliveryPartnerName,
      this.paid});

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['order_id'],
      date: json['order_date']?.toString() ?? 'N/A',
      address: json['order_address']?.toString() ?? 'N/A',
      paymentType: json['payment_type']?.toString() ?? 'N/A',
      deliveryPartnerName: json['DeliveryPartnerName']?.toString() ?? 'N/A',
      paid: json['paid_status'] ?? false,
    );
  }
}
