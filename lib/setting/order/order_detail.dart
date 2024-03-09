import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:pronto/utils/network/service.dart';

class OrderDetailPage extends StatefulWidget {
  final int salesOrderId;

  const OrderDetailPage({Key? key, required this.salesOrderId})
      : super(key: key);

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<OrderDetailCustomer> orderDetails;

  @override
  void initState() {
    super.initState();
    orderDetails = fetchOrderDetails();
  }

  Future<OrderDetailCustomer> fetchOrderDetails() async {
    // Replace with your actual API URL
    final storage = FlutterSecureStorage();
    final customerId = await storage.read(key: 'customerId');

    Map<String, dynamic> body = {
      'sales_order_id': widget.salesOrderId,
      'customer_id': int.parse(customerId!),
    };

    final networkService = NetworkService();
    final response = await networkService.postWithAuth('/sales-order-details',
        additionalData: body);

    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return OrderDetailCustomer.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load order details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: const Text('Order Details'),
      ),
      body: FutureBuilder<OrderDetailCustomer>(
        future: orderDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          } else if (snapshot.hasData) {
            return buildOrderDetails(snapshot.data!);
          } else {
            return const Center(child: Text('No order details found'));
          }
        },
      ),
    );
  }

  Widget buildOrderDetails(OrderDetailCustomer orderDetail) {
    // Parse the ISO 8601 string to DateTime
    DateTime parsedTime = DateTime.parse(orderDetail.orderPlacedTime);

    // Add 5 hours and 30 minutes to the parsedTime
    DateTime adjustedTime = parsedTime.add(Duration(hours: 5, minutes: 30));

    // Create a new DateFormat
    DateFormat formatter = DateFormat(
        'MMMM dd, yyyy hh:mm a'); // Example format: "July 20, 2021 - 03:30 PM"

    // Format the adjusted DateTime object
    String formattedTime = formatter.format(adjustedTime);

    return ListView(
      children: [
        ListTile(
          title: const Text('Order Placed Time'),
          subtitle: Text(formattedTime),
        ),
        for (var item in orderDetail.items)
          ListTile(
            title: Text(item.itemName),
            subtitle: Text(
                'Quantity: ${item.itemQuantity}, Size: ${item.itemSize} ${item.unitOfQuantity}'),
          ),
        Container(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            'Subtotal: ${orderDetail.fees.subtotal}',
            style: TextStyle(fontWeight: FontWeight.w300),
          ),
        ),
      ],
    );
  }
}

class OrderDetailCustomer {
  final String orderPlacedTime;
  final List<ItemDetail> items;
  final ShoppingCartFees fees;

  OrderDetailCustomer({
    required this.orderPlacedTime,
    required this.items,
    required this.fees,
  });

  factory OrderDetailCustomer.fromJson(Map<String, dynamic> json) {
    var itemsJson = json['items'] as List;
    List<ItemDetail> itemsList =
        itemsJson.map((i) => ItemDetail.fromJson(i)).toList();
    return OrderDetailCustomer(
      orderPlacedTime: json['orderPlacedTime'],
      items: itemsList,
      fees: ShoppingCartFees.fromJson(json['fees']),
    );
  }
}

class ItemDetail {
  final String itemName;
  final int itemQuantity;
  final int itemSize;
  final String unitOfQuantity;

  ItemDetail({
    required this.itemName,
    required this.itemQuantity,
    required this.itemSize,
    required this.unitOfQuantity,
  });

  factory ItemDetail.fromJson(Map<String, dynamic> json) {
    return ItemDetail(
      itemName: json['itemName'],
      itemQuantity: json['itemQuantity'],
      itemSize: json['itemSize'],
      unitOfQuantity: json['unitOfQuantity'],
    );
  }
}

class ShoppingCartFees {
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

  ShoppingCartFees({
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

  factory ShoppingCartFees.fromJson(Map<String, dynamic> json) {
    return ShoppingCartFees(
      itemCost: json['itemCost'],
      deliveryFee: json['deliveryFee'],
      platformFee: json['platformFee'],
      smallOrderFee: json['smallOrderFee'],
      rainFee: json['rainFee'],
      highTrafficSurcharge: json['highTrafficSurcharge'],
      packagingFee: json['packagingFee'],
      peakTimeSurcharge: json['peakTimeSurcharge'],
      subtotal: json['subtotal'],
      discounts: json['discounts'],
    );
  }
}
