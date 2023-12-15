import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pronto/cart/cart.dart';
import 'package:pronto/home/address/address_screen.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/globals.dart';
import 'package:provider/provider.dart';
// Import other necessary packages

class AddressSelectionWidget extends StatefulWidget {
  const AddressSelectionWidget({Key? key}) : super(key: key);

  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {
  List<Address> addresses = []; // Replace with your Address model
  bool isLoadingGetAddress = true;
  int? selectedAddressIndex;
  Address? defaultAddress; // Your default address object
  String customerId = "0";
  String phone = "0";

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    getAllAddresses();
    // Initialize your data here
  }

  Future<void> retrieveCustomerInfo() async {
    print("Enter retreive");
    String? storedCustomerId = await storage.read(key: 'customerId');
    String? storedPhone = await storage.read(key: 'phone');

    CartModel cartModel = CartModel(storedCustomerId!);
    Address? deliveryAddress = cartModel.deliveryAddress;

    setState(() {
      customerId = storedCustomerId;
      phone = storedPhone ?? "0";
      //addressId = deliveryAddress.id;
    });

    //print("AddressId: $addressId");
  }

  Future<void> getAllAddresses() async {
    await retrieveCustomerInfo();
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    print("Customer $customerId");

    final Map<String, dynamic> body = {
      "customer_id":
          int.parse(customerId) // Replace with the actual customer_id value
    };

    // Send the HTTP POST request
    final http.Response response = await http.post(
      Uri.parse("$baseUrl/address"),
      headers: headers,
      body: jsonEncode(body), // Convert the Map to a JSON string
    );

    // Check the response
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty && response.contentLength! > 3) {
        //print("address Response Not Empty ${response.contentLength}");
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Address> items =
            jsonData.map((item) => Address.fromJson(item)).toList();
        setState(() {
          print("Success $addresses");
          addresses = items;
          isLoadingGetAddress = false;
        });
      } else {
        setState(() {
          // print("Empty Response");
          isLoadingGetAddress = false;
        });
        print("Error in getAllAddress(): ${response.reasonPhrase}");
      }
    }
  }

  Future<Address?> setDefaultAddress(int addressId) async {
    print("Enter Set Default address");
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    final Map<String, dynamic> body = {
      "customer_id": int.parse(customerId),
      "address_id": addressId,
      "is_default": true
    };

    try {
      final http.Response response = await http.post(
        Uri.parse("$baseUrl/address"),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final decodedResponse = json.decode(response.body);
          if (decodedResponse is Map) {
            // Explicitly cast the response to Map<String, dynamic>
            return Address.fromJson(Map<String, dynamic>.from(decodedResponse));
          } else if (decodedResponse is List) {
            // Handle the case where the response is a List
            final List<Address> items = (decodedResponse)
                .map(
                    (item) => Address.fromJson(Map<String, dynamic>.from(item)))
                .toList();
            return items.isNotEmpty ? items[0] : null;
          }
        }
      } else {
        print("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Exception occurred: $e");
    }
    return null;
  }

  // Add other methods as needed, like fetchAddresses, setDefaultAddress, etc.

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text(
          'Address',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            _buildAdvertisement(),
            _buildTitleSection(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(
                    bottom: 10, top: 5, left: 5, right: 5),
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
                child: Column(
                  children: [
                    Expanded(
                      child: isLoadingGetAddress
                          ? _buildSkeletonLoader()
                          : _buildAddressList(),
                    ),
                  ],
                ),
              ),
            ),

            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvertisement() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        //border: Border.all(color: Colors.grey, width: 1.0),
      ),
      child: Image.asset(
        'assets/icon/icon.jpeg',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      //width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
          child: const Center(
            child: Text(
              "Select Address",
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 5, // Number of skeleton items
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          child: Container(
            height: 60.0, // Height of each skeleton loader item
            decoration: BoxDecoration(
              color: Colors.grey[300], // Light grey color for the skeleton
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                left: BorderSide(color: Colors.deepPurpleAccent, width: 1.0),
                right: BorderSide(color: Colors.deepPurpleAccent, width: 1.0),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressList() {
    var cart = context.watch<CartModel>();
    print("length : ${addresses.length}");

    selectedAddressIndex = 0; // Assuming current address is initially selected

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter modalSetState) {
        return ListView.builder(
          itemCount: addresses.length + 2,
          itemBuilder: (BuildContext context, int index) {
            bool isSelected = index == selectedAddressIndex;

            if (index == 0) {
              // "Add New Address" tile
              return ListTile(
                leading: const Icon(Icons.add, size: 25),
                title: const Text("Add New Address",
                    style: TextStyle(fontSize: 20)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const AddressScreen()),
                  );
                },
              );
            } else {
              // Address tiles
              return InkWell(
                onTap: () {
                  modalSetState(() {
                    selectedAddressIndex = index;
                  });
                  print("selectedAddressIndex: $selectedAddressIndex");
                  // Debug print statement
                  if (selectedAddressIndex! > 1) {
                    // Ensure the index is for an address and not for the "Add New Address" tile
                    Address selectedAddress =
                        addresses[selectedAddressIndex! - 2];
                    print(
                        "Selected Address ID: ${selectedAddress.id}, Street Address: ${selectedAddress.streetAddress}");
                  } else if (selectedAddressIndex == 1) {
                    print(
                        "Selected Address ID: ${cart.deliveryAddress.id}, Street Address: ${cart.deliveryAddress.streetAddress}");
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.greenAccent : Colors.white,
                    border: const Border(
                      top: BorderSide(width: 0.5, color: Colors.grey),
                      bottom: BorderSide(width: 0.5, color: Colors.grey),
                    ),
                  ),
                  child: ListTile(
                    leading: index == 1
                        ? const Icon(Icons.home)
                        : null, // Icon for current address
                    title: Text(
                      index == 1
                          ? cart.deliveryAddress.streetAddress
                          : addresses[index - 2].streetAddress,
                      style: const TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildActionButton() {
    var cart = context.watch<CartModel>();
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: ElevatedButton(
        onPressed: () async {
          try {
            String snackBarMessage;
            print("Button Press: SelectedAddressindex $selectedAddressIndex");
            if (selectedAddressIndex != null) {
              if (selectedAddressIndex! > 1) {
                print("1a Branch");
                showAddress = false;
                setDefaultAddress(addresses[selectedAddressIndex! - 2].id)
                    .then((address) {
                  if (address != null) {
                    cart.deliveryAddress = address;
                  }
                });
                snackBarMessage =
                    'Delivery address set to: ${addresses[selectedAddressIndex! - 2].streetAddress}';

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(snackBarMessage),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushNamed(context, MyHomePage.routeName);
              } else if (cart.deliveryAddress.streetAddress.isNotEmpty) {
                print("1b Branch");

                Navigator.pushNamed(context, MyHomePage.routeName);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please Add Address.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else if (cart.deliveryAddress.streetAddress.isNotEmpty) {
              print("2nd Branch");

              /*
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyHomePage(title: 'Otto Mart')),
              );
              */
              Navigator.pushNamed(context, MyHomePage.routeName);
            } else {
              print("3rd Branch");

              snackBarMessage = 'No Address Selected';
              if (!mounted) {
                return; // Check if the widget is still mounted
              }
              showDialog(
                  context: context,
                  builder: (context) {
                    Future.delayed(const Duration(seconds: 1), () {
                      Navigator.of(context).pop(true);
                    });
                    return const AlertDialog(
                      title: Text('No Address Selected'),
                    );
                  });
            }

            // Close the bottom sheet
          } catch (error) {
            print(error);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error Found'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.deepPurpleAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
        ),
        child: const Text("Deliver To Address", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

// Define other necessary classes/models like Address, etc.