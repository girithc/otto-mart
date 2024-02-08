import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:packer/firebase_options.dart';
import 'package:packer/pack/scanner.dart';
import 'package:packer/quick-add/listen-barcode.dart';
import 'package:packer/shelf/shelf.dart';
import 'package:packer/store/item-detail/item-detail.dart';
import 'package:packer/pack/checklist.dart';
import 'package:packer/stock/add-stock.dart';
import 'package:packer/store/stores.dart';
import 'package:packer/utils/constants.dart';
import 'package:packer/utils/login/page/phone.dart';
import 'package:packer/utils/login/provider/loginProvider.dart';
import 'package:packer/utils/settings/settings.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    // Check if any Firebase apps have been initialized
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => LoginProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scooter Animation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        // Assuming checkLogin() is an asynchronous method that returns a Future<bool>
        future: Provider.of<LoginProvider>(context, listen: false).checkLogin(),
        builder: (context, snapshot) {
          // Check if the future is complete
          if (snapshot.connectionState == ConnectionState.done) {
            // If the user is logged in
            if (snapshot.data == true) {
              return const MyHomePage();
            } else {
              // If the user is not logged in
              return const MyPhone();
            }
          } else {
            // Show loading indicator while waiting for login check
            return const CircularProgressIndicator();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1.0,
          shadowColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'Hi Packer',
            style: TextStyle(
                color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
          ),
          leading: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              child: const Icon(Icons.person)),
        ),
        body: const InventoryManagement()
        //const Stores(), // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement> {
  final ItemDetailApiClient apiClient = ItemDetailApiClient();
  List<PackedItem> packedItems = [];
  List<PackerItemDetail> prePackedItems = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool allPacked = false;
  //PackerItemResponse? packerItemResponse;
  int? orderId;
  int totalQuantity = 0;

  String? _scanBarcodeResult;

  Future<void> scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      setState(() {
        _scanBarcodeResult = barcodeScanRes;
      });
      //_showBarcodeResultDialog(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version';
      // TODO
    }

    if (_scanBarcodeResult != '-1') {
      apiClient.fetchItemFromBarcode(_scanBarcodeResult!).then((success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddStock(item: success)),
        );
      }, onError: (error) {
        // Handle error here if fetchItemFromBarcode fails
        print("Error fetching item: $error");
      });
    }

    if (!mounted) return;
  }

  Future<DeliveryPartnerDispatchResult?> scanBarcodeDispatch() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      setState(() {
        _scanBarcodeResult = barcodeScanRes;
      });

      print("Result: $_scanBarcodeResult");

      if (_scanBarcodeResult != '-1' && _scanBarcodeResult != null) {
        // Split the result to extract `phone` and `salesOrderId`
        final parts = _scanBarcodeResult!.split('-');
        if (parts.length != 2) {
          // Handle error: the format does not match expected 'phone-salesOrderId'
          return null;
        }

        String phone = parts[0];
        int salesOrderId;
        try {
          salesOrderId = int.parse(parts[1]);
        } catch (e) {
          // Handle error: salesOrderId is not a valid integer
          return null;
        }

        final response = await http.post(
          Uri.parse('$baseUrl/delivery-partner-dispatch-order'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'phone': phone,
            'sales_order_id': salesOrderId,
          }),
        );

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          return DeliveryPartnerDispatchResult.fromJson(result);

          // Use dispatchResult as needed, for example, show a success dialog
        } else {
          // Handle server errors or invalid responses
        }
      }
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version';
      // Handle exception
    }

    if (!mounted) return null;
    return null;
  }

// Define the DeliveryPartnerDispatchResult class to parse the JSON response

  Future<void> scanQR() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
      _showBarcodeResultDialog(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version';
      // TODO
    }

    if (!mounted) return;
    setState(() {
      _scanBarcodeResult = barcodeScanRes;
    });
  }

  void _showBarcodeResultDialog(String barcodeResult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scan Result'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Barcode Type: ${barcodeResult.startsWith("http") ? "QR Code" : "Barcode"}'),
                Text('Result: $barcodeResult'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> fetchItems() async {
    String? packerId = await _storage.read(key: "packerId");
    String? storeId = await _storage.read(key: "storeId");
    var url = Uri.parse('$baseUrl/packer-pack-order');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(
          {"store_id": int.parse(storeId!), "packer_phone": packerId}),
    );

    if (response.statusCode == 200) {
      print('response: ${response.body}');
      final jsonResponse = json.decode(response.body);
      if (jsonResponse.isNotEmpty) {
        final combinedResponse = CombinedOrderResponse.fromJson(jsonResponse);
        // Calculate the sum of quantities

        setState(() {
          packedItems = combinedResponse.packedItems;
          prePackedItems = combinedResponse.packedDetails;
          allPacked = combinedResponse.allPacked;
          orderId = packedItems.isNotEmpty ? packedItems[0].orderId : null;

          // Calculate the sum of quantities
          totalQuantity = combinedResponse.packedDetails
              .fold(0, (int sum, item) => sum + (item.quantity ?? 0));
        });
        return true;
      } else {
        return false;
      }
    } else {
      print("Error ${response.body}");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Stores()),
                )
              },
              child: Center(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.1,
                  width: MediaQuery.of(context).size.width * 0.85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15), // Rounded borders
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.25), // Shadow color
                        spreadRadius: 0,
                        blurRadius: 20, // Increased shadow blur
                        offset:
                            const Offset(0, 10), // Increased vertical offset
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Stores',
                      style: TextStyle(
                          fontSize: 25,
                          color: Colors.black,
                          fontWeight: FontWeight.normal),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ListenBarcodePage()),
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.1,
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), // Rounded borders
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.25), // Shadow color
                      spreadRadius: 0,
                      blurRadius: 20, // Increased shadow blur
                      offset: const Offset(0, 10), // Increased vertical offset
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Add+ Item Detail',
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: scanBarcode,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.1,
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), // Rounded borders
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.25), // Shadow color
                      spreadRadius: 0,
                      blurRadius: 20, // Increased shadow blur
                      offset: const Offset(0, 10), // Increased vertical offset
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Add+ Item Quick',
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                fetchItems().then((value) {
                  if (value) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderChecklistPage(
                          packedItems: packedItems,
                          prePackedItems: prePackedItems,
                          allPacked: allPacked,
                          orderId: orderId!,
                          totalQuantity: totalQuantity,
                        ),
                      ),
                    );
                  } else {
                    // Show a Snackbar when there is no order to pack
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Center(
                          child: Text(
                            'No order to pack',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color.fromARGB(255, 255, 188, 188),
                      ),
                    );
                  }
                });
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.2,
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25), // Rounded borders
                  color: Colors.deepPurpleAccent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.25), // Shadow color
                      spreadRadius: 0,
                      blurRadius: 20, // Increased shadow blur
                      offset: const Offset(0, 10), // Increased vertical offset
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Pack Order',
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                scanBarcodeDispatch().then((value) {
                  if (value != null) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Scan Result'),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                Text(
                                    'Delivery Partner Name: ${value.deliveryPartnerName}'),
                                Text('Order Status: ${value.orderStatus}'),
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Close'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                }).catchError((error) {
                  // Handle any errors that occurred during scanBarcodeDispatch execution
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              Text('An error occurred: $error'),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                });
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.15,
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25), // Rounded borders
                  color: const Color.fromARGB(255, 108, 55, 255),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.25), // Shadow color
                      spreadRadius: 0,
                      blurRadius: 20, // Increased shadow blur
                      offset: const Offset(0, 10), // Increased vertical offset
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Dispatch Order',
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShelfPage()),
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.1,
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), // Rounded borders
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.25), // Shadow color
                      spreadRadius: 0,
                      blurRadius: 20, // Increased shadow blur
                      offset: const Offset(0, 10), // Increased vertical offset
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Shelf Management',
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Scanner(),
                  ),
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.1,
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), // Rounded borders
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.25), // Shadow color
                      spreadRadius: 0,
                      blurRadius: 20, // Increased shadow blur
                      offset: const Offset(0, 10), // Increased vertical offset
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Scanner',
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15), // Rounded borders
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDF98FA), // Light purple
            Color(0xFF9055FF), // Darker purple
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25), // Shadow color
            spreadRadius: 0,
            blurRadius: 20, // Increased shadow blur
            offset: const Offset(0, 10), // Increased vertical offset
          ),
        ],
      ),
    );
  }
}

class DeliveryPartnerDispatchResult {
  final String deliveryPartnerName;
  final int salesOrderId;
  final String orderStatus;

  DeliveryPartnerDispatchResult({
    required this.deliveryPartnerName,
    required this.salesOrderId,
    required this.orderStatus,
  });

  factory DeliveryPartnerDispatchResult.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerDispatchResult(
      deliveryPartnerName: json['delivery_partner_name'],
      salesOrderId: json['sales_order_id'],
      orderStatus: json['order_status'],
    );
  }
}
