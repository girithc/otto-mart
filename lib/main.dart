import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:packer/firebase_options.dart';
import 'package:packer/pack/scanner.dart';
import 'package:packer/load/listen-barcode.dart';
import 'package:packer/shelf/shelf.dart';
import 'package:packer/store/item-detail/item-detail.dart';
import 'package:packer/pack/checklist.dart';
import 'package:packer/stock/add-stock.dart';
import 'package:packer/store/stores.dart';
import 'package:packer/utils/login/page/phone.dart';
import 'package:packer/utils/login/provider/loginProvider.dart';
import 'package:packer/utils/network/service.dart';
import 'package:packer/utils/settings/settings.dart';
import 'package:provider/provider.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RemoteMessage? initialMessage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getfcm();
    firebaseInit();
  }

  void firebaseInit() {
    FirebaseMessaging.onMessage.listen((event) {
      RemoteNotification? notification = event.notification;
      AndroidNotification? android = event.notification?.android;

      if (notification != null && android != null) {
        print("Notification: ${notification.title}");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title!),
            content: Text(notification.body!),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              )
            ],
          ),
        );
      }
    });
  }

  Future<void> getfcm() async {
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  }

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
              if (initialMessage != null) {
                print("Initial Message: ${initialMessage!.data}");
                return const MyHomePage();

                // Handle the initial message here
              } else {
                return const MyHomePage();
              }
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
    return const Scaffold(body: InventoryManagement());
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

        Map<String, dynamic> body = {
          'phone': phone,
          'sales_order_id': salesOrderId,
        };

        final networkService = NetworkService();
        final response = await networkService.postWithAuth(
            '/delivery-partner-dispatch-order',
            additionalData: body);

        print(
            "response: ${response.body} ${response.statusCode} ${response.request}");

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
    String? phone = await _storage.read(key: "phone");
    //String? storeId = await _storage.read(key: "storeId");

    Map<String, dynamic> data = {"store_id": 1, "packer_phone": phone};

    print("Data: $data");

    final networkService = NetworkService();
    var response = await networkService.postWithAuth('/packer-pack-order',
        additionalData: data);

    if (response.statusCode == 200) {
      print('response pack: ${response.body}');
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                )
              },
              child: Container(
                margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.05),
                height: MediaQuery.of(context).size.height * 0.2,
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icon/icon.jpeg'),
                  ],
                ),
              ),
            ),
            Container(
                height: MediaQuery.of(context).size.height * 0.05,
                color: Colors.white),
            Container(
              color: Colors.white,
              child: Column(
                children: [
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
                        borderRadius:
                            BorderRadius.circular(15), // Rounded borders
                        color: const Color.fromARGB(255, 108, 55, 255),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.grey.withOpacity(0.25), // Shadow color
                            spreadRadius: 0,
                            blurRadius: 20, // Increased shadow blur
                            offset: const Offset(
                                0, 10), // Increased vertical offset
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Load',
                              style: TextStyle(
                                  fontSize: 36,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            const Icon(
                              Icons.storage_outlined,
                              size: 40,
                              color: Colors.white,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
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
                                      Text(
                                          'Order Status: ${value.orderStatus}'),
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
                        borderRadius:
                            BorderRadius.circular(25), // Rounded borders
                        color: const Color.fromARGB(255, 108, 55, 255),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.grey.withOpacity(0.25), // Shadow color
                            spreadRadius: 0,
                            blurRadius: 20, // Increased shadow blur
                            offset: const Offset(
                                0, 10), // Increased vertical offset
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Delivery',
                              style: TextStyle(
                                  fontSize: 36,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            const Icon(
                              Icons.electric_bike_outlined,
                              size: 40,
                              color: Colors.white,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
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
                              backgroundColor:
                                  Color.fromARGB(255, 255, 188, 188),
                            ),
                          );
                        }
                      });
                    },
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.2,
                      width: MediaQuery.of(context).size.width * 0.85,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(25), // Rounded borders
                        color: const Color.fromARGB(255, 108, 55, 255),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.grey.withOpacity(0.25), // Shadow color
                            spreadRadius: 0,
                            blurRadius: 20, // Increased shadow blur
                            offset: const Offset(
                                0, 10), // Increased vertical offset
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Pack',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            const Icon(
                              Icons.shopping_cart_outlined,
                              size: 40,
                              color: Colors.white,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
  final int location;

  DeliveryPartnerDispatchResult(
      {required this.deliveryPartnerName,
      required this.salesOrderId,
      required this.orderStatus,
      required this.location});

  factory DeliveryPartnerDispatchResult.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerDispatchResult(
      deliveryPartnerName: json['delivery_partner_name'],
      salesOrderId: json['sales_order_id'],
      orderStatus: json['order_status'],
      location: json['location'],
    );
  }
}
