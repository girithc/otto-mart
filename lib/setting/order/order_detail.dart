import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pronto/utils/constants.dart';

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
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'sales_order_id': widget.salesOrderId,
        'customer_id': int.parse(customerId!)
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load order details');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              var item = data[index];
              return ListTile(
                leading: Image.network(item['image']),
                title: Text(item['name']),
                // Add more fields as needed
              );
            },
          );
        },
      ),
    );
  }
}
