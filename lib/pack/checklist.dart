import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/store/item-detail/item-detail.dart';
import 'package:packer/main.dart';
import 'package:packer/utils/network/service.dart';

// ignore: must_be_immutable
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
  bool _isLoading = false;
  bool _isAssigningSpace = false;

  List<PackedItem> packedItems = [];
  List<PackerItemDetail?> prePackedItems = [];
  bool allPacked = false;
  bool pictureTaken = false;
  //PackerItemResponse? packerItemResponse;

  int? orderId;
  int totalQuantity = 0; // New variable to store total quantity

  int? selectedRow;
  String? selectedColumn;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> cancelPackOrder() async {
    String? packerPhone = await _storage.read(key: "phone");
    String? storeId = await _storage.read(key: "storeId");

    //var url = Uri.parse('$baseUrl/packer-cancel-order');
    Map<String, dynamic> data = {
      "packer_phone": packerPhone,
      "store_id": 1,
      "order_id": widget.packedItems[0].orderId,
    };

    final networkService = NetworkService();

    final response = await networkService.postWithAuth('/packer-cancel-order',
        additionalData: data);

    if (response.statusCode == 200) {
      print('response: ${response.body}');
      return true;
    } else {
      // Handle error
      print("Error ${response.body}");
      return false;
    }
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.0)),
            child: Text(
              'Assign Space',
              textAlign: TextAlign.center,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedRow,
                      decoration: InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true),
                      items: List.generate(28, (index) => index + 1)
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(
                            value.toString(),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedRow = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 10),
                  primary: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () {
                  if (selectedRow != null) {
                    scanBarcodeAssignSpace(selectedRow!);
                    Navigator.of(context).pop();
                  } else {
                    // Handle case where row or column is not selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.white,

                        content: Text(
                          'Please select both row and column',
                          style: TextStyle(color: Colors.black),
                        ),
                        duration: Duration(
                            seconds: 2), // Customize duration as needed
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> scanBarcode(String code) async {
    print("Scanned barcode: $code ");

    if (code != '-1') {
      setState(() {
        _isLoading = true; // Start loading
      });

      apiClient
          .fetchItemFromBarcodeInSalesOrder(code, widget.orderId, "1")
          .then((item) {
        setState(() {
          widget.prePackedItems = item.itemList;
          widget.totalQuantity =
              item.itemList.fold(0, (sum, item) => sum + item.quantity);
          widget.allPacked = item.allPacked;
          _isLoading = false; // Stop loading after data is fetched
        });
      }, onError: (error) {
        setState(() {
          _isLoading = false; // Stop loading on error
          print("Error fetching item: $error");
          // Optionally show an error message or handle the error differently
        });
      });
    }
  }

  Future<void> scanBarcodeAssignSpace(int horizontal) async {
    print("Entered scanBarcodeAssignSpace");
    print(" Location ${horizontal.toString()}");
    String? phone = await _storage.read(key: "phone");
    String? packerId = await _storage.read(key: "packerId");

    //String? storeId = await _storage.read(key: "storeId");
    print("Checkpoint 1");

    setState(() {
      _isAssigningSpace = true; // Start loading
    });
    final path =
        'packer/sales-order/$packerId/${widget.orderId}-${TimeOfDay.now()}';
    final ref = FirebaseStorage.instance.ref().child(path);
    String urlDownloaded = ''; // Initialize urlDownloaded with an empty string

    try {
      setState(() {
        uploadTask = ref.putFile(_image!);
      });
      final snapshot = await uploadTask!.whenComplete(() => {});
      urlDownloaded = await snapshot.ref
          .getDownloadURL(); // Attempt to get the download URL
      print('Downloaded Link: $urlDownloaded');
    } catch (e) {
      // If the upload fails, urlDownloaded remains an empty string
      print('Image upload failed: $e');
    } finally {
      // Ensure uploadTask is set to null whether upload succeeds or fails
      setState(() {
        uploadTask = null;
      });
    }
    try {
      print("Checkpoint III");

      apiClient
          .orderAssignSpace(
              horizontal, phone!, widget.orderId, "1", urlDownloaded)
          .then((allocationInfo) {
        // Show the allocation details in a dialog
        _showAllocationDetailsDialog(allocationInfo);
        setState(() {
          _isAssigningSpace = false;
        });
      }, onError: (error) {
        _showErrorDialog("Error: $error"); // Show error dialog

        setState(() {
          _isAssigningSpace = false;
        });
      });
    } catch (e) {
      setState(() {
        _isAssigningSpace = false;
      });
      _showErrorDialog("Error: $e");
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
                Text('Shelf ${allocationInfo.location}'),
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
        centerTitle: true,
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
        onBarcodeScanned: (String code) {
          if (widget.allPacked) {
            //scanBarcodeAssignSpace(code);
          } else {
            scanBarcode(code);
          }
        },
        child: widget.packedItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: <Widget>[
                                Column(
                                  children: [
                                    item.imageURLs.isNotEmpty
                                        ? GestureDetector(
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
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.6,
                                                        errorBuilder:
                                                            (BuildContext
                                                                    context,
                                                                Object
                                                                    exception,
                                                                StackTrace?
                                                                    stackTrace) {
                                                          return Container(
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.4,
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.3,
                                                            color: Colors
                                                                .grey[200],
                                                            alignment: Alignment
                                                                .center,
                                                            child: const Center(
                                                              child: Text(
                                                                'no image',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .grey),
                                                              ),
                                                            ),
                                                          );
                                                        }, // Adjust height as needed
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
                                                                  MaterialStateProperty.all<
                                                                          Color>(
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
                                            child: Image.network(
                                              item.imageURLs.first,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.2,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.35, // Increased width

                                              errorBuilder:
                                                  (BuildContext context,
                                                      Object exception,
                                                      StackTrace? stackTrace) {
                                                return Container(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.2,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.35, // Increased width

                                                  color: Colors.grey[200],
                                                  alignment: Alignment.center,
                                                  child: const Center(
                                                    child: Text(
                                                      'no image',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : const SizedBox(width: 40, height: 40),
                                    const SizedBox(
                                      height: 2.0,
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // Align children to the top
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.55,
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.55,
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        item.brand,
                                        style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontSize: 18),
                                      ),
                                    ), // Display item name
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.55,
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        'size: ${item.quantity} ${item.unitOfQuantity}',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          decoration: const BoxDecoration(
                                              color: Colors.amberAccent,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    10.0), // Set the rounded corner radius
                                              )),
                                          child: Text(
                                            'Amount: ${item.itemQuantity}',
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 2),
                                      decoration: const BoxDecoration(
                                          color: Colors.tealAccent,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      child: Text(
                                        'Location  ${item.shelfVertical}-${item.shelfHorizontal}',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text("Help"),
                                              content: const Text(
                                                  "This is the help dialog content."),
                                              actions: <Widget>[
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.black,
                                                    backgroundColor: Colors
                                                        .white, // Text color
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.0), // Roundish borders
                                                    ),
                                                    elevation:
                                                        5, // The elevation of the button
                                                  ),
                                                  child: const Text('Close'),
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // Close the dialog
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .end, // Align this row's child to the end, effectively aligning it to the right
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.50,
                                            padding: const EdgeInsets.only(
                                                top: 10, bottom: 10),
                                            child: const Text(
                                              'help',
                                              textAlign: TextAlign
                                                  .right, // Align the text to the right within the container
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                          const Icon(
                                            Icons
                                                .help_outline, // The help center icon
                                            color: Colors
                                                .black, // Specify the color of the icon if needed
                                          ),
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
                                  value:
                                      (quantityPacked ?? 0) / item.itemQuantity,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.blue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        /*
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
                      */
      ),
      bottomNavigationBar: Material(
        elevation: 4.0,
        child: Container(
          padding: const EdgeInsets.only(bottom: 10, top: 5, left: 5, right: 5),
          child: widget.allPacked
              ? (ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent, // Background color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12), // Makes the button longer and taller
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20), // Roundish borders
                    ),
                  ),
                  onPressed: scanMobileBarcodeAssignSpace,
                  child: _isAssigningSpace
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Complete Packing',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                )

                  /*
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent, // Background color
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12), // Makes the button longer and taller
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // Roundish borders
                        ),
                      ),
                      onPressed: _takePicture,
                      child: const Text(
                        'Take Picture',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                    */
                  )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // First FAB

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent, // Background color
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 10), // Makes the button longer and taller
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Roundish borders
                        ),
                      ),
                      onPressed: scanMobileBarcode,
                      child: const Text(
                        'Scan Item',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    /*
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
                    */
                  ],
                ),
        ),
      ),
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
  int shelfHorizontal;
  String shelfVertical;

  PackedItem({
    required this.itemId,
    required this.orderId,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.unitOfQuantity,
    required this.itemQuantity,
    required this.imageURLs,
    required this.shelfHorizontal,
    required this.shelfVertical,
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
      imageURLs: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      shelfHorizontal: json['shelf_horizontal'],
      shelfVertical: json['shelf_vertical'],
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

  CombinedOrderResponse({
    required this.packedItems,
    required this.packedDetails,
    required this.allPacked,
  });

  factory CombinedOrderResponse.fromJson(Map<String, dynamic> json) {
    var packedItemsJson = json['packed_items'] as List<dynamic>?;
    var packedItems = packedItemsJson != null
        ? packedItemsJson.map((x) => PackedItem.fromJson(x)).toList()
        : <PackedItem>[];

    var packedDetailsJson = json['packed_details'] as List<dynamic>?;
    var packedDetails = packedDetailsJson != null
        ? packedDetailsJson.map((x) => PackerItemDetail.fromJson(x)).toList()
        : <PackerItemDetail>[];

    var allPacked = json['all_packed'] as bool;

    return CombinedOrderResponse(
      packedItems: packedItems,
      packedDetails: packedDetails,
      allPacked: allPacked,
    );
  }
}
