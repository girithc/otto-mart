import 'dart:async';
import 'dart:convert';

import 'package:delivery/utils/network/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final networkService = NetworkService();
  List<OrderAssignResponse> ordersAssigned = [];
  OrderAssigned? orderAssigned;
  DeliveryOrderDetails? deliveryOrderDetails;
  ArriveOrderDetails? arriveOrderDetails;
  PastOrderDetails? orderDetails;

  final _storage = FlutterSecureStorage();
  TextEditingController _cashCollectedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    GetAllAssignedOrders();
    CheckForNewOrder();
  }

  @override
  void dispose() {
    _cashCollectedController.dispose();
    super.dispose();
  }

  Future<void> CheckForNewOrder() async {
    // Simulate a network request
    final phone = await _storage.read(key: "phone");
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    Map<String, dynamic> body = {
      'phone': phone,
    };

    try {
      final response = await networkService.postWithAuth(
          '/delivery-partner-check-order', // Adjusted endpoint
          additionalData: body);

      //print("CheckForOrder Response status code: ${response.statusCode} Response body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          // Deserialize the JSON response into an OrderAssigned object
          orderAssigned = OrderAssigned.fromJson(jsonDecode(response.body));
          // Now you can use orderAssigned in your UI or state management
        });
      } else {
        // Handle null response or null body...
        print("Response or response body is null");
      }
    } catch (e) {
      // Handle exceptions...
      print("Exception caught: $e");
    }
  }

  Future<void> GetAllAssignedOrders() async {
    final phone = await _storage.read(key: "phone");

    Map<String, dynamic> body = {'store_id': 1, 'phone': phone};

    final response = await networkService.postWithAuth(
        '/delivery-partner-get-assigned-orders',
        additionalData: body);

    //print(" Response body: ${response.body}");

    if (response.statusCode == 200) {
      // Assuming the response body contains an array of orders
      List<dynamic> jsonResponse = json.decode(response.body);
      setState(() {
        ordersAssigned = jsonResponse
            .map((orderJson) => OrderAssignResponse.fromJson(orderJson))
            .toList();
      });

      //print(ordersAssigned);
    } else {
      print(response.body);
    }
  }

  Future<void> AcceptOrder() async {
    final phone = await _storage.read(key: "phone");
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    Map<String, dynamic> body = {
      'phone': phone,
      'sales_order_id': orderAssigned!.id,
    };

    final response = await networkService.postWithAuth(
        '/delivery-partner-accept-order', // Adjusted endpoint
        additionalData: body);

    //print("Response status code: ${response.statusCode} Response body: ${response.body}");
    if (response.statusCode == 200) {
      // Assuming the response body contains an array of orders
      List<dynamic> jsonResponse = json.decode(response.body);
      setState(() {
        ordersAssigned = jsonResponse
            .map((orderJson) => OrderAssignResponse.fromJson(orderJson))
            .toList();
        orderAssigned = null;
      });

      //print(ordersAssigned);
    } else {
      //print(response.body);
    }
  }

  Future<void> PickupOrder() async {}

  Future<void> deliverOrder(int id) async {
    final phone = await _storage.read(key: "phone");
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    Map<String, dynamic> body = {
      'phone': phone,
      'sales_order_id': id,
    };

    final response = await networkService.postWithAuth(
        '/delivery-partner-deliver-order', // Adjusted endpoint
        additionalData: body);

    print(
        "Response status code: ${response.statusCode} Response body: ${response.body}");
    if (response.statusCode == 200) {
      // Deserialize the JSON response into the DeliveryOrderDetails object
      final jsonResponse = json.decode(response.body);

      // Now you can use deliveryOrderDetails in your state
      setState(() {
        deliveryOrderDetails = DeliveryOrderDetails.fromJson(jsonResponse);
      });
    } else {
      print(response.body);
    }
  }

  Future<void> arriveOrder(int id) async {
    final phone = await _storage.read(key: "phone");
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    Map<String, dynamic> body = {
      'phone': phone,
      'sales_order_id': id,
    };

    final response = await networkService.postWithAuth(
      '/delivery-partner-arrive-destination', // Adjusted endpoint
      additionalData: body,
    );

    print(
        "Response status code: ${response.statusCode} Response body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      // Use arriveOrderDetails in your state
      setState(() {
        arriveOrderDetails = ArriveOrderDetails.fromJson(jsonResponse);
      });
    } else {
      print(response.body);
    }
  }

  Future<void> getOrderDetails(int id) async {
    final phone = await _storage.read(key: "phone");
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    Map<String, dynamic> body = {
      'phone': phone,
      'sales_order_id': id,
    };

    final response = await networkService.postWithAuth(
      '/delivery-partner-get-order-details', // Adjusted endpoint
      additionalData: body,
    );

    print(
        "Response status code: ${response.statusCode} Response body: ${response.body}");
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        orderDetails = PastOrderDetails.fromJson(jsonResponse);
      });
    } else {
      print(response.body);
    }
  }

  Future<DeliveryCompletionResult?> completeOrder(int id) async {
    final phone = await _storage.read(key: "phone");
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    int amountCollected = 0;
    if (arriveOrderDetails!.paymentType == "cash") {
      amountCollected = int.parse(_cashCollectedController.text);
    }
    Map<String, dynamic> body = {
      'phone': phone,
      'sales_order_id': id,
      'amount_collected': amountCollected,
    };

    final response = await networkService.postWithAuth(
      '/delivery-partner-complete-order', // Adjusted endpoint
      additionalData: body,
    );

    print(
        "Response status code: ${response.statusCode} Response body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      // Update the function to return an instance of DeliveryCompletionResult
      return DeliveryCompletionResult.fromJson(jsonResponse);
    } else {
      print(response.body);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh), // Using the refresh icon
            onPressed: () {
              // Call the getAllOrders function when the icon is pressed
              GetAllAssignedOrders();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: ordersAssigned.length,
                    itemBuilder: (context, index) {
                      final order = ordersAssigned[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          color: order.orderStatus == "completed"
                              ? Colors.grey
                              : Colors
                                  .transparent, // Set the color to grey if completed, otherwise transparent

                          child: ListTile(
                            title: Text('Order ID: ${order.orderId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('OTP: ${order.orderOTP}',
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 14)),
                              ],
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 1),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: Text(
                                'Order ${order.orderStatus}',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                            ),
                            onTap: () {
                              // Implement navigation or action on tap
                              if (order.orderStatus != "dispatched" &&
                                  order.orderStatus != "arrived" &&
                                  order.orderStatus != "completed") {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Order ID 31'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "OTP: ${order.orderOTP}",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 20),
                                          ),
                                          Text(
                                            'Status "${order.orderStatus}".',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 18),
                                          ),
                                        ],
                                      ),
                                      actions: <Widget>[
                                        ElevatedButton(
                                          child: Text('OK'),
                                          onPressed: () {
                                            GetAllAssignedOrders();

                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ).then((value) => {
                                      GetAllAssignedOrders(),
                                    });
                              } else if (order.orderStatus == "dispatched") {
                                deliverOrder(order.orderId).then((value) => {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            content: SingleChildScrollView(
                                              child: ListBody(children: [
                                                FormBuilderTextField(
                                                  name: 'customername',
                                                  decoration: InputDecoration(
                                                    labelText: 'Customer Name',
                                                    hintText: 'Customer Name',
                                                    filled:
                                                        true, // Enable filling of the input
                                                    fillColor: Colors.grey[
                                                        200], // Set light grey color as the background
                                                    border: OutlineInputBorder(
                                                      // Define the border
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Circular rounded border
                                                      borderSide: BorderSide
                                                          .none, // No border side
                                                    ),
                                                  ),
                                                  initialValue:
                                                      deliveryOrderDetails!
                                                          .customerName,
                                                  readOnly: true,
                                                ),
                                                const SizedBox(height: 15),
                                                FormBuilderTextField(
                                                  name: 'customerphone',
                                                  decoration: InputDecoration(
                                                    labelText: 'Customer Phone',
                                                    hintText: 'Customer Phone',
                                                    filled:
                                                        true, // Enable filling of the input
                                                    fillColor: Colors.grey[
                                                        200], // Set light grey color as the background
                                                    border: OutlineInputBorder(
                                                      // Define the border
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Circular rounded border
                                                      borderSide: BorderSide
                                                          .none, // No border side
                                                    ),
                                                  ),
                                                  readOnly: true,
                                                  initialValue:
                                                      deliveryOrderDetails!
                                                          .customerPhone,
                                                ),
                                                const SizedBox(height: 15),
                                                FormBuilderTextField(
                                                  name: 'streetaddress',
                                                  decoration: InputDecoration(
                                                    labelText: 'Street Address',
                                                    hintText: 'Street Address',
                                                    filled:
                                                        true, // Enable filling of the input
                                                    fillColor: Colors.grey[
                                                        200], // Set light grey color as the background
                                                    border: OutlineInputBorder(
                                                      // Define the border
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Circular rounded border
                                                      borderSide: BorderSide
                                                          .none, // No border side
                                                    ),
                                                  ),
                                                  initialValue:
                                                      deliveryOrderDetails!
                                                          .streetAddress,
                                                  readOnly: true,
                                                ),
                                                const SizedBox(height: 15),
                                                FormBuilderTextField(
                                                  name: 'addresslineone',
                                                  decoration: InputDecoration(
                                                    labelText: 'Address Line 1',
                                                    hintText: 'Address Line 1',
                                                    filled:
                                                        true, // Enable filling of the input
                                                    fillColor: Colors.grey[
                                                        200], // Set light grey color as the background
                                                    border: OutlineInputBorder(
                                                      // Define the border
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Circular rounded border
                                                      borderSide: BorderSide
                                                          .none, // No border side
                                                    ),
                                                  ),
                                                  initialValue:
                                                      deliveryOrderDetails!
                                                          .lineOneAddress,
                                                  readOnly: true,
                                                ),
                                                const SizedBox(height: 15),
                                                FormBuilderTextField(
                                                  name: 'addresslinetwo',
                                                  decoration: InputDecoration(
                                                    labelText: 'Address Line 2',
                                                    hintText: 'Address Line 2',
                                                    filled:
                                                        true, // Enable filling of the input
                                                    fillColor: Colors.grey[
                                                        200], // Set light grey color as the background
                                                    border: OutlineInputBorder(
                                                      // Define the border
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Circular rounded border
                                                      borderSide: BorderSide
                                                          .none, // No border side
                                                    ),
                                                  ),
                                                  initialValue:
                                                      deliveryOrderDetails!
                                                          .lineTwoAddress,
                                                  readOnly: true,
                                                ),
                                                const SizedBox(height: 15),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .tealAccent, // Light grey background
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  20.0), // Rounded borders
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        double latitude =
                                                            deliveryOrderDetails!
                                                                .latitude; // Example latitude
                                                        double longitude =
                                                            deliveryOrderDetails!
                                                                .longitude; // Example longitude
                                                        Uri googleMapsUri =
                                                            Uri.parse(
                                                                "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");

                                                        if (await canLaunchUrl(
                                                            googleMapsUri)) {
                                                          await launchUrl(
                                                              googleMapsUri);
                                                        } else {
                                                          throw 'Could not open the map.';
                                                        }
                                                      },
                                                      child: const Text(
                                                        'Google Maps',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .black, // Text color
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 20),
                                                ...deliveryOrderDetails!.items
                                                    .map((item) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text('${item.itemName}',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      Text(
                                                          'Quantity: ${item.itemQuantity}  Size: ${item.itemSize} ${item.unitOfQuantity}'),

                                                      const SizedBox(
                                                          height:
                                                              15), // Add some spacing between items
                                                    ],
                                                  );
                                                }).toList(),
                                                const SizedBox(height: 20),
                                              ]),
                                            ),
                                            actions: <Widget>[
                                              ElevatedButton(
                                                child:
                                                    Text('Arrive At Location'),
                                                onPressed: () {
                                                  arriveOrder(order.orderId)
                                                      .then((value) => {
                                                            GetAllAssignedOrders()
                                                          });
                                                  Navigator.of(context)
                                                      .pop(); // Close the dialog
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) => {
                                            GetAllAssignedOrders(),
                                          })
                                    });
                              } else if (order.orderStatus == "arrived") {
                                arriveOrder(order.orderId).then((value) => {
                                      _cashCollectedController.clear(),
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          bool showWarning = false;
                                          return StatefulBuilder(
                                              builder: (context, setState) {
                                            return AlertDialog(
                                              content: SingleChildScrollView(
                                                child: ListBody(children: [
                                                  SizedBox(
                                                    height: 25,
                                                  ),
                                                  if (showWarning)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 10),
                                                      child: Text(
                                                        'Please enter the cash collected amount.',
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      ),
                                                    ),
                                                  TextField(
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'Amount to Collect',
                                                      filled: true,
                                                      fillColor: Colors
                                                              .lightBlue[
                                                          100], // Light blue color
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10.0), // Rounded border
                                                      ),
                                                    ),
                                                    readOnly: true,
                                                    controller: TextEditingController(
                                                        text: arriveOrderDetails!
                                                            .subtotal
                                                            .toString()), // Assuming subtotal is the amount to collect
                                                  ),
                                                  const SizedBox(height: 15),
                                                  // Cash Collected (Editable by the user)
                                                  arriveOrderDetails!
                                                              .paymentType ==
                                                          "cash"
                                                      ? TextField(
                                                          controller:
                                                              _cashCollectedController, // Define this TextEditingController in your widget state
                                                          keyboardType:
                                                              TextInputType
                                                                  .number, // Ensure numeric input
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                'Cash Collected',
                                                            filled: true,
                                                            fillColor: Colors
                                                                    .green[
                                                                100], // Light green color
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0), // Rounded border
                                                            ),
                                                          ),
                                                        )
                                                      : TextField(
                                                          controller: TextEditingController(
                                                              text: arriveOrderDetails!
                                                                  .paymentType), // Define this TextEditingController in your widget state
                                                          keyboardType:
                                                              TextInputType
                                                                  .number, // Ensure numeric input
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                'Payment Type',
                                                            filled: true,
                                                            fillColor: Colors
                                                                    .green[
                                                                100], // Light green color
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0), // Rounded border
                                                            ),
                                                          ),
                                                          readOnly: true,
                                                        ),

                                                  const SizedBox(height: 20),

                                                  // Conditional warning text
                                                  if (showWarning)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 10),
                                                      child: Text(
                                                        'Please enter the cash collected amount.',
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      ),
                                                    ),

                                                  FormBuilderTextField(
                                                    name: 'customername',
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'Customer Name',
                                                      hintText: 'Customer Name',
                                                      filled:
                                                          true, // Enable filling of the input
                                                      fillColor: Colors.grey[
                                                          200], // Set light grey color as the background
                                                      border:
                                                          OutlineInputBorder(
                                                        // Define the border
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10.0), // Circular rounded border
                                                        borderSide: BorderSide
                                                            .none, // No border side
                                                      ),
                                                    ),
                                                    initialValue:
                                                        arriveOrderDetails!
                                                            .customerName,
                                                    readOnly: true,
                                                  ),
                                                  const SizedBox(height: 15),
                                                  FormBuilderTextField(
                                                    name: 'customerphone',
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'Customer Phone',
                                                      hintText:
                                                          'Customer Phone',
                                                      filled:
                                                          true, // Enable filling of the input
                                                      fillColor: Colors.grey[
                                                          200], // Set light grey color as the background
                                                      border:
                                                          OutlineInputBorder(
                                                        // Define the border
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10.0), // Circular rounded border
                                                        borderSide: BorderSide
                                                            .none, // No border side
                                                      ),
                                                    ),
                                                    readOnly: true,
                                                    initialValue:
                                                        arriveOrderDetails!
                                                            .customerPhone,
                                                  ),
                                                  const SizedBox(height: 15),
                                                  FormBuilderTextField(
                                                    name: 'streetaddress',
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'Street Address',
                                                      hintText:
                                                          'Street Address',
                                                      filled:
                                                          true, // Enable filling of the input
                                                      fillColor: Colors.grey[
                                                          200], // Set light grey color as the background
                                                      border:
                                                          OutlineInputBorder(
                                                        // Define the border
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10.0), // Circular rounded border
                                                        borderSide: BorderSide
                                                            .none, // No border side
                                                      ),
                                                    ),
                                                    initialValue:
                                                        arriveOrderDetails!
                                                            .streetAddress,
                                                    readOnly: true,
                                                  ),
                                                  const SizedBox(height: 15),
                                                  FormBuilderTextField(
                                                    name: 'addresslineone',
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'Address Line 1',
                                                      hintText:
                                                          'Address Line 1',
                                                      filled:
                                                          true, // Enable filling of the input
                                                      fillColor: Colors.grey[
                                                          200], // Set light grey color as the background
                                                      border:
                                                          OutlineInputBorder(
                                                        // Define the border
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10.0), // Circular rounded border
                                                        borderSide: BorderSide
                                                            .none, // No border side
                                                      ),
                                                    ),
                                                    initialValue:
                                                        arriveOrderDetails!
                                                            .lineOneAddress,
                                                    readOnly: true,
                                                  ),
                                                  const SizedBox(height: 15),
                                                  FormBuilderTextField(
                                                    name: 'addresslinetwo',
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'Address Line 2',
                                                      hintText:
                                                          'Address Line 2',
                                                      filled:
                                                          true, // Enable filling of the input
                                                      fillColor: Colors.grey[
                                                          200], // Set light grey color as the background
                                                      border:
                                                          OutlineInputBorder(
                                                        // Define the border
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10.0), // Circular rounded border
                                                        borderSide: BorderSide
                                                            .none, // No border side
                                                      ),
                                                    ),
                                                    initialValue:
                                                        arriveOrderDetails!
                                                            .lineTwoAddress,
                                                    readOnly: true,
                                                  ),
                                                  const SizedBox(height: 15),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        style: TextButton
                                                            .styleFrom(
                                                          backgroundColor: Colors
                                                              .tealAccent, // Light grey background
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20.0), // Rounded borders
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          double latitude =
                                                              arriveOrderDetails!
                                                                  .latitude; // Example latitude
                                                          double longitude =
                                                              arriveOrderDetails!
                                                                  .longitude; // Example longitude
                                                          Uri googleMapsUri =
                                                              Uri.parse(
                                                                  "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");

                                                          if (await canLaunchUrl(
                                                              googleMapsUri)) {
                                                            await launchUrl(
                                                                googleMapsUri);
                                                          } else {
                                                            throw 'Could not open the map.';
                                                          }
                                                        },
                                                        child: const Text(
                                                          'Google Maps',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .black, // Text color
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 20),

                                                  ...arriveOrderDetails!.items
                                                      .map((item) {
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text('${item.itemName}',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        Text(
                                                            'Quantity: ${item.itemQuantity}  Size: ${item.itemSize} ${item.unitOfQuantity}'),

                                                        const SizedBox(
                                                            height:
                                                                15), // Add some spacing between items
                                                      ],
                                                    );
                                                  }).toList(),
                                                  const SizedBox(height: 20),
                                                ]),
                                              ),
                                              actions: <Widget>[
                                                ElevatedButton(
                                                  child: Text('Complete Order'),
                                                  onPressed: () {
                                                    if (_cashCollectedController
                                                            .text.isEmpty &&
                                                        arriveOrderDetails!
                                                                .paymentType ==
                                                            "cash") {
                                                      // Update local state to show the warning
                                                      setState(() {
                                                        showWarning = true;
                                                      });
                                                    } else {
                                                      // Process the completion of the order
                                                      completeOrder(
                                                              order.orderId)
                                                          .then((value) => {
                                                                GetAllAssignedOrders(),
                                                              });
                                                      Navigator.of(context)
                                                          .pop(); // Close the dialog
                                                    }
                                                  },
                                                ),
                                              ],
                                            );
                                          });
                                        },
                                      ).then((value) => {
                                            GetAllAssignedOrders(),
                                          })
                                    });
                              } else if (order.orderStatus == "completed") {
                                getOrderDetails(order.orderId).then((value) => {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            content: SingleChildScrollView(
                                              child: ListBody(children: [
                                                SizedBox(
                                                  height: 25,
                                                ),

                                                TextField(
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        'Amount to Collect',
                                                    filled: true,
                                                    fillColor: Colors.lightBlue[
                                                        100], // Light blue color
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Rounded border
                                                    ),
                                                  ),
                                                  readOnly: true,
                                                  controller: TextEditingController(
                                                      text: orderDetails!
                                                          .subtotal
                                                          .toString()), // Assuming subtotal is the amount to collect
                                                ),
                                                const SizedBox(height: 15),
                                                // Cash Collected (Editable by the user)
                                                orderDetails!.paymentType ==
                                                        "cash"
                                                    ? TextField(
                                                        controller: TextEditingController(
                                                            text: orderDetails!
                                                                .amountCollected
                                                                .toString()), // Define this TextEditingController in your widget state
                                                        keyboardType: TextInputType
                                                            .number, // Ensure numeric input
                                                        decoration:
                                                            InputDecoration(
                                                          labelText:
                                                              'Cash Collected',
                                                          filled: true,
                                                          fillColor: Colors
                                                                  .green[
                                                              100], // Light green color
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10.0), // Rounded border
                                                          ),
                                                        ),
                                                      )
                                                    : TextField(
                                                        controller:
                                                            TextEditingController(
                                                                text: orderDetails!
                                                                    .paymentType), // Define this TextEditingController in your widget state
                                                        keyboardType: TextInputType
                                                            .number, // Ensure numeric input
                                                        decoration:
                                                            InputDecoration(
                                                          labelText:
                                                              'Payment Type',
                                                          filled: true,
                                                          fillColor: Colors
                                                                  .green[
                                                              100], // Light green color
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10.0), // Rounded border
                                                          ),
                                                        ),
                                                        readOnly: true,
                                                      ),

                                                const SizedBox(height: 20),

                                                // Conditional warning text

                                                FormBuilderTextField(
                                                  name: 'customername',
                                                  decoration: InputDecoration(
                                                    labelText: 'Customer Name',
                                                    hintText: 'Customer Name',
                                                    filled:
                                                        true, // Enable filling of the input
                                                    fillColor: Colors.grey[
                                                        200], // Set light grey color as the background
                                                    border: OutlineInputBorder(
                                                      // Define the border
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Circular rounded border
                                                      borderSide: BorderSide
                                                          .none, // No border side
                                                    ),
                                                  ),
                                                  initialValue: orderDetails!
                                                      .customerName,
                                                  readOnly: true,
                                                ),
                                                const SizedBox(height: 15),
                                                FormBuilderTextField(
                                                  name: 'customerphone',
                                                  decoration: InputDecoration(
                                                    labelText: 'Customer Phone',
                                                    hintText: 'Customer Phone',
                                                    filled:
                                                        true, // Enable filling of the input
                                                    fillColor: Colors.grey[
                                                        200], // Set light grey color as the background
                                                    border: OutlineInputBorder(
                                                      // Define the border
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Circular rounded border
                                                      borderSide: BorderSide
                                                          .none, // No border side
                                                    ),
                                                  ),
                                                  readOnly: true,
                                                  initialValue: orderDetails!
                                                      .customerPhone,
                                                ),
                                                const SizedBox(height: 15),
                                                FormBuilderTextField(
                                                  name: 'streetaddress',
                                                  decoration: InputDecoration(
                                                    labelText: 'Street Address',
                                                    hintText: 'Street Address',
                                                    filled:
                                                        true, // Enable filling of the input
                                                    fillColor: Colors.grey[
                                                        200], // Set light grey color as the background
                                                    border: OutlineInputBorder(
                                                      // Define the border
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Circular rounded border
                                                      borderSide: BorderSide
                                                          .none, // No border side
                                                    ),
                                                  ),
                                                  initialValue: orderDetails!
                                                      .streetAddress,
                                                  readOnly: true,
                                                ),
                                                const SizedBox(height: 15),
                                                FormBuilderTextField(
                                                  name: 'addresslineone',
                                                  decoration: InputDecoration(
                                                    labelText: 'Address Line 1',
                                                    hintText: 'Address Line 1',
                                                    filled:
                                                        true, // Enable filling of the input
                                                    fillColor: Colors.grey[
                                                        200], // Set light grey color as the background
                                                    border: OutlineInputBorder(
                                                      // Define the border
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Circular rounded border
                                                      borderSide: BorderSide
                                                          .none, // No border side
                                                    ),
                                                  ),
                                                  initialValue: orderDetails!
                                                      .lineOneAddress,
                                                  readOnly: true,
                                                ),
                                                const SizedBox(height: 15),
                                                FormBuilderTextField(
                                                  name: 'addresslinetwo',
                                                  decoration: InputDecoration(
                                                    labelText: 'Address Line 2',
                                                    hintText: 'Address Line 2',
                                                    filled:
                                                        true, // Enable filling of the input
                                                    fillColor: Colors.grey[
                                                        200], // Set light grey color as the background
                                                    border: OutlineInputBorder(
                                                      // Define the border
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0), // Circular rounded border
                                                      borderSide: BorderSide
                                                          .none, // No border side
                                                    ),
                                                  ),
                                                  initialValue: orderDetails!
                                                      .lineTwoAddress,
                                                  readOnly: true,
                                                ),
                                                const SizedBox(height: 15),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .tealAccent, // Light grey background
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  20.0), // Rounded borders
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        double latitude =
                                                            orderDetails!
                                                                .latitude; // Example latitude
                                                        double longitude =
                                                            orderDetails!
                                                                .longitude; // Example longitude
                                                        Uri googleMapsUri =
                                                            Uri.parse(
                                                                "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");

                                                        if (await canLaunchUrl(
                                                            googleMapsUri)) {
                                                          await launchUrl(
                                                              googleMapsUri);
                                                        } else {
                                                          throw 'Could not open the map.';
                                                        }
                                                      },
                                                      child: const Text(
                                                        'Google Maps',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .black, // Text color
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 20),

                                                ...orderDetails!.items
                                                    .map((item) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text('${item.itemName}',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      Text(
                                                          'Quantity: ${item.itemQuantity}  Size: ${item.itemSize} ${item.unitOfQuantity}'),

                                                      const SizedBox(
                                                          height:
                                                              15), // Add some spacing between items
                                                    ],
                                                  );
                                                }).toList(),
                                                const SizedBox(height: 20),
                                              ]),
                                            ),
                                            actions: <Widget>[
                                              ElevatedButton(
                                                child: Text('Ok'),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) => {
                                            GetAllAssignedOrders(),
                                          })
                                    });
                              }
                              //print('Tapped on order ID: ${order.orderId}');
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                (orderAssigned == null || orderAssigned!.id == 0)
                    ? GestureDetector(
                        onTap: () {
                          CheckForNewOrder();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.grey,
                                offset: Offset(0, 1),
                                blurRadius: 1.0,
                              ),
                            ],
                          ),
                          margin: EdgeInsets.only(bottom: 10, top: 20),
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: const Text(
                            'Check for Order',
                            style: TextStyle(fontSize: 25),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          AcceptOrder();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.deepPurpleAccent,
                                Colors.deepPurple,
                              ], // Gradient colors
                            ),
                          ),
                          margin: EdgeInsets.only(bottom: 10, top: 20),
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: const Text(
                            'Accept Order',
                            style: TextStyle(
                                fontSize: 25,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                SizedBox(
                  height: 10,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderAssignResponse {
  final int orderId;
  final String orderStatus;
  final DateTime orderDate;
  final String orderOTP;

  OrderAssignResponse({
    required this.orderId,
    required this.orderStatus,
    required this.orderDate,
    required this.orderOTP,
  });

  factory OrderAssignResponse.fromJson(Map<String, dynamic> json) {
    return OrderAssignResponse(
      orderId: json['order_id'],
      orderStatus: json['order_status'],
      orderDate: DateTime.parse(json['order_date']),
      orderOTP: json['order_otp'],
    );
  }
}

class OrderAssigned {
  final int id;
  final int storeId;
  final DateTime orderDate;
  final String orderStatus;

  OrderAssigned({
    required this.id,
    required this.storeId,
    required this.orderDate,
    required this.orderStatus,
  });

  factory OrderAssigned.fromJson(Map<String, dynamic> json) {
    return OrderAssigned(
      id: json['id'] as int,
      storeId: json['store_id'] as int,
      orderDate: DateTime.parse(json['order_date'] as String),
      orderStatus: json['order_status'] as String,
    );
  }
}

class DeliveryOrderDetails {
  final String customerName;
  final String customerPhone;
  final double latitude;
  final double longitude;
  final String lineOneAddress;
  final String lineTwoAddress;
  final String streetAddress;
  final DateTime orderDate;
  final String orderStatus;
  final String orderOTP;
  final List<OrderDetail> items;

  DeliveryOrderDetails({
    required this.customerName,
    required this.customerPhone,
    required this.latitude,
    required this.longitude,
    required this.lineOneAddress,
    required this.lineTwoAddress,
    required this.streetAddress,
    required this.orderDate,
    required this.orderStatus,
    required this.orderOTP,
    required this.items,
  });

  factory DeliveryOrderDetails.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List;
    List<OrderDetail> itemsList =
        list.map((i) => OrderDetail.fromJson(i)).toList();

    return DeliveryOrderDetails(
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      lineOneAddress: json['line_one_address'],
      lineTwoAddress: json['line_two_address'],
      streetAddress: json['street_address'],
      orderDate: DateTime.parse(json['order_date']),
      orderStatus: json['order_status'],
      orderOTP: json['order_otp'],
      items: itemsList,
    );
  }
}

class OrderDetail {
  final String itemName;
  final int itemQuantity;
  final int itemSize;
  final String unitOfQuantity;
  final DateTime orderPlacedTime;

  OrderDetail({
    required this.itemName,
    required this.itemQuantity,
    required this.itemSize,
    required this.unitOfQuantity,
    required this.orderPlacedTime,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      itemName: json['ItemName'] as String, // Corrected key
      itemQuantity: json['ItemQuantity'] as int, // Corrected key
      itemSize: json['ItemSize'] as int, // Corrected key
      unitOfQuantity: json['UnitOfQuantity'] as String, // Corrected key
      orderPlacedTime: DateTime.parse(json['OrderPlacedTime']), // Corrected key
    );
  }
}

class ArriveOrderDetails {
  final String customerName;
  final String customerPhone;
  final double latitude;
  final double longitude;
  final String lineOneAddress;
  final String lineTwoAddress;
  final String streetAddress;
  final DateTime orderDate;
  final String orderStatus;
  final String orderOTP;
  final List<OrderDetail> items; // Assuming OrderDetail is already defined
  final int subtotal;
  final bool paid;
  final String paymentType;

  ArriveOrderDetails({
    required this.customerName,
    required this.customerPhone,
    required this.latitude,
    required this.longitude,
    required this.lineOneAddress,
    required this.lineTwoAddress,
    required this.streetAddress,
    required this.orderDate,
    required this.orderStatus,
    required this.orderOTP,
    required this.items,
    required this.subtotal,
    required this.paid,
    required this.paymentType,
  });

  factory ArriveOrderDetails.fromJson(Map<String, dynamic> json) {
    var itemsFromJson = json['items'] as List;
    List<OrderDetail> itemsList =
        itemsFromJson.map((i) => OrderDetail.fromJson(i)).toList();

    return ArriveOrderDetails(
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      lineOneAddress: json['line_one_address'],
      lineTwoAddress: json['line_two_address'],
      streetAddress: json['street_address'],
      orderDate: DateTime.parse(json['order_date']),
      orderStatus: json['order_status'],
      orderOTP: json['order_otp'],
      items: itemsList,
      subtotal: json['subtotal'],
      paid: json['paid'],
      paymentType: json['payment_type'],
    );
  }
}

class DeliveryCompletionResult {
  final bool success;

  DeliveryCompletionResult({required this.success});

  factory DeliveryCompletionResult.fromJson(Map<String, dynamic> json) {
    return DeliveryCompletionResult(
      success: json['success'],
    );
  }
}

class PastOrderDetails {
  final String customerName;
  final String customerPhone;
  final double latitude;
  final double longitude;
  final String lineOneAddress;
  final String lineTwoAddress;
  final String streetAddress;
  final DateTime orderDate;
  final String orderStatus;
  final String orderOTP;
  final List<OrderDetail> items; // Assuming OrderDetail is already defined
  final int subtotal;
  final bool paid;
  final String paymentType;
  final int amountCollected;

  PastOrderDetails({
    required this.customerName,
    required this.customerPhone,
    required this.latitude,
    required this.longitude,
    required this.lineOneAddress,
    required this.lineTwoAddress,
    required this.streetAddress,
    required this.orderDate,
    required this.orderStatus,
    required this.orderOTP,
    required this.items,
    required this.subtotal,
    required this.paid,
    required this.paymentType,
    required this.amountCollected,
  });

  factory PastOrderDetails.fromJson(Map<String, dynamic> json) {
    var itemsFromJson = json['items'] as List;
    List<OrderDetail> itemsList =
        itemsFromJson.map((i) => OrderDetail.fromJson(i)).toList();

    return PastOrderDetails(
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      lineOneAddress: json['line_one_address'],
      lineTwoAddress: json['line_two_address'],
      streetAddress: json['street_address'],
      orderDate: DateTime.parse(json['order_date']),
      orderStatus: json['order_status'],
      orderOTP: json['order_otp'],
      items: itemsList,
      subtotal: json['subtotal'],
      paid: json['paid'],
      paymentType: json['payment_type'],
      amountCollected: json['amount_collected'],
    );
  }
}
