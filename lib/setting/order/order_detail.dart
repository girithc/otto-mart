import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/network/service.dart';

class OrderDetailPage extends StatefulWidget {
  final int salesOrderId;

  const OrderDetailPage({super.key, required this.salesOrderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final storage = const FlutterSecureStorage();
  late Future<List<dynamic>> orderDetails;

  @override
  void initState() {
    super.initState();
    orderDetails = fetchOrderDetails();
  }

  Future<List<dynamic>> fetchOrderDetails() async {
    final customerId = await storage.read(key: 'customerId');
    final url = Uri.parse('$baseUrl/sales-order-details');
    final Map<String, dynamic> body = {
      'sales_order_id': widget.salesOrderId,
      'customer_id': int.parse(customerId!)
    };

    final networkService = NetworkService();
    final response = await networkService.postWithAuth('/sales-order-details',
        additionalData: body);

    /*
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'sales_order_id': widget.salesOrderId,
        'customer_id': int.parse(customerId!)
      }),
    );
    */

    print("Response Order Details: ${response.statusCode} ${response.body}");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load order details');
    }
  }

  @override
  Widget build(BuildContext context) {
    var itemNameStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: orderDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No order details found'));
          }

          List<dynamic> data = snapshot.data!;
          return Container(
            width: MediaQuery.of(context).size.width,
            margin:
                const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: const Offset(0, 2), // Changes position of shadow
                ),
              ],
              border: Border.all(color: Colors.white, width: 1.0),
            ),
            child: ListView.builder(
              itemCount: data.length + 1,
              itemBuilder: (context, index) {
                print("Index $index");
                if (index < data.length) {
                  var item = data[index];
                  return Container(
                    //padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                                // Add border
                                ),
                            child: Center(
                                child:
                                    Image.network(item["image"], height: 75)),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Container(
                            decoration: const BoxDecoration(
                                //border: Border.all( color: Colors.black), // Add border
                                ),
                            child: Text(
                              item["name"],
                              style: itemNameStyle,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.deepPurpleAccent, // Add border
                                  borderRadius: BorderRadius.circular(8.0)),
                              height: MediaQuery.of(context).size.height * 0.04,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Spacer(),
                                    Text(
                                      item["quantity"].toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              )),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: const BoxDecoration(
                                // Add border
                                ),
                            child: Center(
                              child: Text(
                                  "\u{20B9}${item["price"] * item["quantity"]}", // Replace with your price calculation
                                  style: itemNameStyle
                                  /*
                                          const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          */
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  var item = data[index - 1];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(15), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset:
                              const Offset(0, 2), // Changes position of shadow
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 1.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Column(
                        children: [
                          _CustomListItem(
                            icon: Icons.done_all_outlined,
                            label: 'Item Total',
                            amount: item["item_cost"].toString(),
                            font: const TextStyle(
                                fontSize: 16, color: Colors.black),
                          ),
                          int.parse(item["small_order_fee"].toString()) > 0
                              ? _CustomListItem(
                                  icon: Icons.donut_small_rounded,
                                  label: 'Small Order Fee',
                                  amount: item["small_order_fee"].toString(),
                                  font: const TextStyle(fontSize: 16),
                                )
                              : Container(),
                          _CustomListItem(
                            icon: Icons.electric_bike_outlined,
                            label: 'Delivery Fee',
                            amount: item["delivery_fee"].toString(),
                            font: const TextStyle(fontSize: 16),
                          ),
                          _CustomListItem(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Platform Fee',
                            amount: item["platform_fee"].toString(),
                            font: const TextStyle(fontSize: 16),
                          ),
                          _CustomListItem(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Packaging Fee',
                            amount: item["packing_fee"].toString(),
                            font: const TextStyle(fontSize: 16),
                          ),
                          const Divider(),
                          _CustomListItem(
                            icon: Icons.payments,
                            label: 'Amount Paid',
                            amount: '\u{20B9}${item["subtotal"].toString()}',
                            font: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _CustomListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? amount; // Change to nullable type
  final TextStyle? font;

  const _CustomListItem({
    required this.icon,
    required this.label,
    this.amount, // Nullable
    this.font,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 10.0, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: font,
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(right: 40, top: 0, bottom: 0),
            child: Text(
              amount ?? '0', // Default to "0" if amount is null
              style: font,
            ),
          ),
        ],
      ),
    );
  }
}
