import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/store/item-detail/item-detail.dart';
import 'package:packer/main.dart';
import 'package:packer/pack/pack-item.dart';
import 'package:packer/stock/add-stock.dart';
import 'package:packer/utils/constants.dart';

class OrderChecklistPage extends StatefulWidget {
  OrderChecklistPage(
      {super.key,
      required this.packedItems,
      required this.prePackedItems,
      required this.allPacked,
      required this.orderId,
      required this.totalQuantity});
  List<PackedItem> packedItems;
  List<PackerItemDetail> prePackedItems;
  bool allPacked;
  int orderId;
  int totalQuantity;
  @override
  State<OrderChecklistPage> createState() => _OrderChecklistPageState();
}

class _OrderChecklistPageState extends State<OrderChecklistPage> {
  // Sample data for the list
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  File? _image;
  UploadTask? uploadTask;

  List<PackedItem> packedItems = [];
  List<PackerItemDetail?> prePackedItems = [];
  bool allPacked = false;
  bool pictureTaken = false;
  //PackerItemResponse? packerItemResponse;

  int? orderId;
  int totalQuantity = 0; // New variable to store total quantity

  @override
  void initState() {
    super.initState();
    //fetchItems();
  }

  Future<void> fetchItems() async {
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
      }
    } else {
      print("Error ${response.body}");
    }
  }

  Future<bool> cancelPackOrder() async {
    String? packerId = await _storage.read(key: "packerId");
    String? storeId = await _storage.read(key: "storeId");

    var url = Uri.parse('$baseUrl/packer-cancel-order');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "packer_id": int.parse(packerId!),
        "store_id": int.parse(storeId!),
        "order_id": widget.packedItems[0].orderId,
      }),
    );

    if (response.statusCode == 200) {
      print('response: ${response.body}');
      return true;
    } else {
      // Handle error
      print("Error ${response.body}");
      return false;
    }
  }

  final ItemDetailApiClient apiClient = ItemDetailApiClient();

  Future<void> scanMobileBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);

      if (barcodeScanRes != '-1') {
        scanBarcode(barcodeScanRes);
      }
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version';
      // TODO
    }

    if (!mounted) return;
  }

  Future<void> scanMobileBarcodeAssignSpace() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);

      if (barcodeScanRes != '-1') {
        scanBarcodeAssignSpace(barcodeScanRes);
      }
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version';
      // TODO
    }

    if (!mounted) return;
  }

  Future<void> scanBarcode(String code) async {
    String barcodeScanRes;
    String? packerId = await _storage.read(key: "packerId");
    String? storeId = await _storage.read(key: "storeId");

    if (code != '-1') {
      apiClient
          .fetchItemFromBarcodeInSalesOrder(
              code, packerId!, widget.orderId, "1")
          .then((item) {
        setState(() {
          widget.prePackedItems = item.itemList;
          widget.totalQuantity =
              item.itemList.fold(0, (sum, item) => sum + item.quantity);
          widget.allPacked = item.allPacked;
        });
      }, onError: (error) {
        // Handle error here if fetchItemFromBarcode fails
        print("Error fetching item: $error");
      });
    }
  }

  Future<void> scanBarcodeAssignSpace(String code) async {
    String? packerId = await _storage.read(key: "packerId");
    String? storeId = await _storage.read(key: "storeId");

    if (code != '-1') {
      final path =
          'packer/sales-order/$packerId/${widget.orderId}-${TimeOfDay.now()}';

      final ref = FirebaseStorage.instance.ref().child(path);
      String urlDownloaded;
      try {
        setState(() {
          uploadTask = ref.putFile(_image!);
        });
        final snapshot = await uploadTask!.whenComplete(() => {});
        urlDownloaded = await snapshot.ref.getDownloadURL();
        print('Downloaded Link: $urlDownloaded');
        setState(() {
          uploadTask = null;
        });

        apiClient
            .orderAssignSpace(
                code, packerId!, widget.orderId, "1", urlDownloaded)
            .then((allocationInfo) {
          // Show the allocation details in a dialog
          _showAllocationDetailsDialog(allocationInfo);
        }, onError: (error) {
          // Handle error here if orderAssignSpace fails
          print("Error: $error");
          _showErrorDialog("Error: $error"); // Show error dialog
        });
      } catch (e) {
        print('Upload failed: $e');
      }
    }
  }

  void _showAllocationDetailsDialog(AllocationInfo allocationInfo) {
    showDialog(
      context: context,
      barrierDismissible: false, // Makes the dialog not dismissable
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Allocation Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Image.network(allocationInfo.image),
                Text('Order ID: ${allocationInfo.salesOrderId}'),
                Text(
                    'Shelf Name ${allocationInfo.column}${allocationInfo.row}'),
                Text('Shelf ID: ${allocationInfo.shelfId}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Complete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                ); // Navigate to MyHomePage
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: true, // Makes the dialog dismissible
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(errorMessage),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      File? compressedFile = await _compressFile(File(pickedFile.path));
      setState(() {
        _image = compressedFile;
        pictureTaken = true;
      });
    }
  }

  Future<File?> _compressFile(File file) async {
    final String targetPath = '${file.path}_compressed.jpg';
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path, targetPath,
      quality: 50, // Adjust the quality as needed
      rotate: 0, // Adjust the rotation as needed
    );

    File resultImg = File(result!.path);

    print('Original file size: ${file.lengthSync()}');
    print('Compressed file size: ${resultImg.lengthSync()}');

    return resultImg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Hero(
          tag: 'heroButton',
          child: Text(
            'Order Checklist',
            style: TextStyle(color: Colors.white),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            cancelPackOrder().then((value) => {
                  if (value)
                    {Navigator.pop(context)}
                  else
                    {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Failed To Cancel Checkout')))
                    }
                });
          },
        ),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: BarcodeKeyboardListener(
        onBarcodeScanned: (code) async {
          widget.allPacked
              ? await scanBarcodeAssignSpace(code)
              : await scanBarcode(code);
        },
        child: widget.packedItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.packedItems.length,
                      itemBuilder: (context, index) {
                        PackedItem item = widget.packedItems[index];
                        int? quantityPacked = widget.prePackedItems
                            .firstWhere(
                              (result) => result.itemId == item.itemId,
                              orElse: () => PackerItemDetail(
                                  itemId: 0,
                                  orderId: 0,
                                  packerId: 0,
                                  quantity:
                                      0), // Return null to match the type PackerItemDetail?
                            )
                            .quantity;

                        print("Quantity Packed $quantityPacked");
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    // Leading widget

                                    Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (item.imageURLs.isNotEmpty) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    content: Image.network(
                                                      item.imageURLs.first,
                                                      width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width *
                                                          0.7, // Use screen width for the image
                                                      height:
                                                          300, // Adjust height as needed
                                                    ),
                                                    actions: <Widget>[
                                                      Center(
                                                        child: TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(), // Close the dialog
                                                          style: ButtonStyle(
                                                            backgroundColor:
                                                                MaterialStateProperty
                                                                    .all<Color>(
                                                                        Colors
                                                                            .white),
                                                          ),
                                                          child: const Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize:
                                                                    20), // Optional: Change text color if needed
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${item.itemQuantity}x',
                                                style: const TextStyle(
                                                    fontSize: 25),
                                              ),
                                              item.imageURLs.isNotEmpty
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8.0),
                                                      child: Image.network(
                                                        item.imageURLs.first,
                                                        height: 90,
                                                        width: 100,
                                                      ),
                                                    )
                                                  : const SizedBox(
                                                      width: 40, height: 40),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 2.0,
                                        ),
                                        const Center(
                                          child: Text(
                                            'Aisle 1A',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        )
                                      ],
                                    ),
                                    // Spacer to push the trailing widget to the end

                                    // Title and subtitle
                                    Row(
                                      children: <Widget>[
                                        SizedBox(
                                          width: 180,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                    fontSize: 18),
                                              ), // Display item name
                                              Text(
                                                '${item.brand}\nQuantity: ${item.quantity} ${item.unitOfQuantity}',
                                                style: const TextStyle(
                                                    fontSize: 18),
                                              ), // Display brand and quantity
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      6.0), // Adjust the radius as needed
                                  child: SizedBox(
                                    height: 30,
                                    child: LinearProgressIndicator(
                                      value: (quantityPacked ?? 0) /
                                          item.itemQuantity,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Colors.blue),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    (widget.allPacked && pictureTaken)
                        ? Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            margin: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              // This adds the rounded borders
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(
                                      0.5), // Shadow color with some transparency
                                  spreadRadius:
                                      2, // Extent of the shadow spread
                                  blurRadius:
                                      4, // How blurry the shadow should be
                                  offset: const Offset(
                                      0, 3), // Changes position of shadow
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              // This is used to clip the image with rounded corners
                              borderRadius: BorderRadius.circular(
                                  10.0), // The same radius as the Container's border
                              child: Image.file(_image!),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: widget.allPacked
            ? (pictureTaken
                ? FloatingActionButton.extended(
                    heroTag: 'packItemButton', // Unique tag for this FAB

                    onPressed: scanMobileBarcodeAssignSpace,
                    backgroundColor: Colors.deepPurpleAccent,
                    label: const Text(
                      'Complete Packing',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : FloatingActionButton.extended(
                    heroTag: 'takepicture', // Unique tag for this FAB

                    onPressed: _takePicture,
                    backgroundColor: Colors.deepPurpleAccent,
                    label: const Text(
                      'Take Picture',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // First FAB

                  FloatingActionButton.extended(
                    heroTag: 'scanItemButton', // Unique tag for this FAB

                    onPressed: scanMobileBarcode,
                    backgroundColor: Colors.deepPurpleAccent,
                    label: const Text(
                      'Scan Item',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 4.0,
                  ),
                  // Second FAB
                  FloatingActionButton(
                    heroTag: 'counterButton', // Unique tag for this FAB

                    onPressed: () {
                      // Define the action for this button
                    },
                    backgroundColor: Colors.deepPurpleAccent,
                    child: Text(
                      "${widget.totalQuantity}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class PackedItem {
  int itemId;
  int orderId;
  String name;
  String brand;
  int quantity;
  String unitOfQuantity;
  int itemQuantity;
  List<String> imageURLs;

  PackedItem({
    required this.itemId,
    required this.orderId,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.unitOfQuantity,
    required this.itemQuantity,
    required this.imageURLs,
  });

  factory PackedItem.fromJson(Map<String, dynamic> json) {
    return PackedItem(
      itemId: json['item_id'],
      orderId: json['order_id'],
      name: json['name'],
      brand: json['brand'],
      quantity: json['quantity'],
      unitOfQuantity: json['unit_of_quantity'],
      itemQuantity: json['item_quantity'],
      imageURLs: List<String>.from(json['image_urls']),
    );
  }
}

class PackerItemDetail {
  final int itemId;
  final int packerId;
  final int orderId;
  final int quantity;

  PackerItemDetail({
    required this.itemId,
    required this.packerId,
    required this.orderId,
    required this.quantity,
  });

  factory PackerItemDetail.fromJson(Map<String, dynamic> json) {
    return PackerItemDetail(
      itemId: json['item_id'],
      packerId: json['packer_id'],
      orderId: json['order_id'],
      quantity: json['quantity'],
    );
  }
}

class PackerItemResponse {
  final List<PackerItemDetail> itemList;
  final bool success;
  final bool allPacked;

  PackerItemResponse(
      {required this.itemList, required this.success, required this.allPacked});

  factory PackerItemResponse.fromJson(Map<String, dynamic> json) {
    return PackerItemResponse(
        itemList: (json['item_list'] as List)
            .map((i) => PackerItemDetail.fromJson(i))
            .toList(),
        success: json['success'],
        allPacked: json['all_packed']);
  }
}

class CombinedOrderResponse {
  List<PackedItem> packedItems;
  List<PackerItemDetail> packedDetails;
  bool allPacked;

  CombinedOrderResponse(
      {required this.packedItems,
      required this.packedDetails,
      required this.allPacked});

  factory CombinedOrderResponse.fromJson(Map<String, dynamic> json) {
    // Handle packed_items
    var packedItemsJson = json['packed_items'] as List<dynamic>?;
    var packedItems = packedItemsJson != null
        ? packedItemsJson.map((x) => PackedItem.fromJson(x)).toList()
        : <PackedItem>[];

    // Handle packed_details
    var packedDetailsJson = json['packed_details'] as List<dynamic>?;
    var packedDetails = packedDetailsJson != null
        ? packedDetailsJson.map((x) => PackerItemDetail.fromJson(x)).toList()
        : <PackerItemDetail>[];

    var allPacked = json['all_packed'] as bool;

    return CombinedOrderResponse(
        packedItems: packedItems,
        packedDetails: packedDetails,
        allPacked: allPacked);
  }
}
