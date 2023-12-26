import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:master/shelf/shelf.dart';
import 'package:master/store/item-detail/item-detail.dart';
import 'package:master/pack/checklist.dart';
import 'package:master/stock/add-stock.dart';
import 'package:master/store/stores.dart';
import 'package:master/utils/constants.dart';
import 'package:master/utils/login/provider/loginProvider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() {
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
      home: const OpeningPageAnimation(),
      debugShowCheckedModeBanner: false, // Add this line
    );
  }
}

class OpeningPageAnimation extends StatefulWidget {
  const OpeningPageAnimation({Key? key}) : super(key: key);

  @override
  _OpeningPageAnimationState createState() => _OpeningPageAnimationState();
}

class _OpeningPageAnimationState extends State<OpeningPageAnimation> {
  late double _begin;
  late double _end;

  @override
  void initState() {
    super.initState();
    _begin = -0.5;
    _end = 1;
  }

  @override
  Widget build(BuildContext context) {
    // Delayed execution to ensure the context is fully established
    Future.delayed(Duration.zero, () {
      Provider.of<LoginProvider>(context, listen: false).checkLogin(context);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: _begin, end: _end),
          duration: const Duration(seconds: 3, milliseconds: 20),
          builder: (BuildContext context, double position, Widget? child) {
            return Transform.translate(
              offset: Offset(position * MediaQuery.of(context).size.width, 0),
              child: Transform.scale(
                scale: 0.75,
                child: child!,
              ),
            );
          },
          onEnd:
              () {}, // Removed navigation as it's handled in the LoginProvider now
          child: Image.asset('assets/scooter.avif'),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 4.0,
          shadowColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            widget.title,
            style: const TextStyle(
                color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
          ),
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
                      color: Colors.black.withOpacity(0.25), // Shadow color
                      spreadRadius: 0,
                      blurRadius: 20, // Increased shadow blur
                      offset: const Offset(0, 10), // Increased vertical offset
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Stores',
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: scanBarcode,
            child: Container(
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
                    color: Colors.black.withOpacity(0.25), // Shadow color
                    spreadRadius: 0,
                    blurRadius: 20, // Increased shadow blur
                    offset: const Offset(0, 10), // Increased vertical offset
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Scan Barcode',
                  style: TextStyle(
                      fontSize: 25,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
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
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.deepPurpleAccent,
                    ),
                  );
                }
              });
            },
            child: Container(
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
                    color: Colors.black.withOpacity(0.25), // Shadow color
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
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShelfPage()),
              );
            },
            child: Container(
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
                    color: Colors.black.withOpacity(0.25), // Shadow color
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
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
            color: Colors.black.withOpacity(0.25), // Shadow color
            spreadRadius: 0,
            blurRadius: 20, // Increased shadow blur
            offset: const Offset(0, 10), // Increased vertical offset
          ),
        ],
      ),
    );
  }
}
