import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:pronto/cart/cart.dart';
import 'package:pronto/home/address/address_screen.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/globals.dart';
import 'package:pronto/utils/network/service.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
// Import other necessary packages

class AddressSelectionWidget extends StatefulWidget {
  const AddressSelectionWidget(
      {this.flag = false, this.initLogin = false, Key? key})
      : super(key: key);
  final bool
      flag; // Make `flag` final to follow best practices for immutable widget properties
  final bool initLogin;
  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {
  List<Address> addresses = []; // Replace with your Address model
  bool isLoadingGetAddress = true;
  int? selectedAddressIndex;
  Address? defaultAddress; // Your default address object
  String? customerId;
  String phone = "0";

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    getAllAddresses();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> retrieveCustomerInfo() async {
    String? storedCustomerId = await storage.read(key: 'customerId');
    String? storedPhone = await storage.read(key: 'phone');

    //CartModel cartModel = CartModel();
    //Address? deliveryAddress = cartModel.deliveryAddress;

    setState(() {
      customerId = storedCustomerId;
      phone = storedPhone ?? "0";
      //addressId = deliveryAddress.id;
    });

    //print("AddressId: $addressId");
  }

  Future<void> getAllAddresses() async {
    customerId = await storage.read(key: 'customerId');

    final Map<String, dynamic> body = {
      "customer_id":
          int.parse(customerId!) // Replace with the actual customer_id value
    };

    final networkService = NetworkService();
    //print("send get all request");
    final response =
        await networkService.postWithAuth('/address', additionalData: body);
    //("\n\n\\n\n\n");

    //print("Address All: ${response.body}");

    //print("\n\n\\n\n\n");
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty && response.contentLength! > 3) {
        final List<dynamic> jsonData = json.decode(response.body);

        //print("Start Json Map");
        final List<Address> items =
            jsonData.map((item) => Address.fromJson(item)).toList();
        //print("End Json Map");

        setState(() {
          addresses = items;
          isLoadingGetAddress = false;
        });
        print("Widget Flag: ${widget.flag}");
        print("Init Login: ${widget.initLogin}");

        if (widget.flag && !widget.initLogin) {
          deliverToAddress(items[0].id).then(
            (resp) async => {
              if (resp!.deliverable)
                {
                  await storage
                      .write(key: 'storeId', value: resp.storeId.toString())
                      .then((value) => {
                            storage
                                .write(
                                    key: 'cartId',
                                    value: resp.cartId.toString())
                                .then((value) => {context.push('/home')})
                          })
                }
              else
                {
                  await storage.delete(key: 'storeId'),
                  context.push('/coming-soon')
                }
            },
          );
        }
      } else {
        if (response.contentLength == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddressScreen()),
          );
        }
        setState(() {
          isLoadingGetAddress = false;
        });
        print("Error in getAllAddress(): ${response.reasonPhrase}");
      }
    }
  }

  Future<AddressResponse?> setDefaultAddress(int addressId) async {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    final customerId = await storage.read(key: 'customerId');

    final Map<String, dynamic> body = {
      "customer_id": int.parse(customerId!),
      "address_id": addressId,
      "is_default": true
    };

    try {
      final networkService = NetworkService();
      final response =
          await networkService.postWithAuth('/address', additionalData: body);

      print("setDefaultAddress Response: ${response.body} ");
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final decodedResponse = json.decode(response.body);
          if (decodedResponse is Map) {
            // Parse and return AddressResponse
            final resp = AddressResponse.fromJson(
                Map<String, dynamic>.from(decodedResponse));

            CartModel cartModel = CartModel();
            Address? deliveryAddress = cartModel.deliveryAddress;
            await storage.write(key: 'cartId', value: resp.cartId.toString());
            await storage.write(key: 'storeId', value: resp.storeId.toString());
            await storage.write(key: 'addressId', value: addressId.toString());

            return resp;
          } else if (decodedResponse is List) {
            // Handle the case where the response is a List
            final List<AddressResponse> items = decodedResponse
                .map((item) =>
                    AddressResponse.fromJson(Map<String, dynamic>.from(item)))
                .toList();
            return items.isNotEmpty ? items[0] : null;
          }
        }
      } else {
        print("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Exception occurred (setDefaultAddress): $e");
    }
    return null;
  }

  Future<DeliverableResponse?> deliverToAddress(int addressId) async {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    customerId = await storage.read(key: 'customerId');

    final Map<String, dynamic> body = {
      "customer_id": int.parse(customerId!),
      "address_id": addressId,
    };

    print("Deliver To Body $body");

    try {
      final networkService = NetworkService();
      final response = await networkService.postWithAuth('/deliver-to',
          additionalData: body);

      print("deliverToAddress Response: ${response.body} ");

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final decodedResponse = json.decode(response.body);
          final resp = DeliverableResponse.fromJson(decodedResponse);
          //print("Setting cartId to ${resp.cartId}");
          CartModel cartModel = CartModel();
          Address? deliveryAddress = cartModel.deliveryAddress;
          await storage.write(key: 'cartId', value: resp.cartId.toString());
          await storage.write(key: 'storeId', value: resp.storeId.toString());
          await storage.write(key: 'addressId', value: addressId.toString());
          return resp;
        }
      } else {
        print("Error: ${response.reasonPhrase}");
        print("Error: ${response.body}");
      }
    } catch (e) {
      print("Exception occurred (deliverToAddress): $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.shade400,
        title: const Text(
          'Select Address',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: widget.flag
            ? Container()
            : IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Colors.white,
                )),
      ),
      body: UpgradeAlert(
        dialogStyle: Platform.isIOS
            ? UpgradeDialogStyle.cupertino
            : UpgradeDialogStyle.material,
        canDismissDialog: false,
        showIgnore: false,
        showLater: false,
        child: Container(
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

              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 5, left: 5, right: 5),
                  padding: const EdgeInsets.symmetric(vertical: 0.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15), // Rounded corners
                    boxShadow: const [],
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

              //_buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvertisement() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      margin: const EdgeInsets.symmetric(vertical: 5),
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

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 5, // Number of skeleton items
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          child: Container(
            height: 60.0, // Height of each skeleton loader item
            decoration: BoxDecoration(
              color: Colors.grey.shade200, // Light grey color for the skeleton
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressList() {
    var cart = context.watch<CartModel>();
    selectedAddressIndex = 0; // Assuming current address is initially selected

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter modalSetState) {
        return ListView.builder(
          itemCount: addresses.length + 1,
          itemBuilder: (BuildContext context, int index) {
            bool isSelected = index == selectedAddressIndex;

            if (index == 0) {
              // "Add New Address" tile
              return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const AddressScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    margin:
                        const EdgeInsets.only(bottom: 10, left: 10, right: 10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.shade400,
                      borderRadius:
                          BorderRadius.circular(15), // Add rounded corners

                      border: Border.all(
                          color: Colors.white,
                          width: 1), // Optional: add a subtle border
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          size: 25,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(" New Address",
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ));
            } else {
              // Address tiles
              return InkWell(
                onTap: () {
                  modalSetState(() {
                    selectedAddressIndex = index;
                  });
                  bool deliverable = true;

                  if (selectedAddressIndex! >= 1) {
                    //print("1a Branch");
                    showAddress = false;
                    setDefaultAddress(addresses[selectedAddressIndex! - 1].id)
                        .then(
                      (address) async {
                        if (!mounted) return;

                        if (address?.address != null) {
                          cart.deliveryAddress = address!.address;
                        }
                        if (!address!.deliverable) {
                          //print('Not Deliverable');
                          deliverable = false;
                        }

                        if (deliverable) {
                          //print('Go To Home');
                          await storage
                              .write(
                                  key: 'storeId',
                                  value: address.storeId.toString())
                              .then((value) => {
                                    storage
                                        .write(
                                            key: 'cartId',
                                            value: address.cartId.toString())
                                        .then(
                                            (value) => {context.push('/home')})
                                  });
                        } else {
                          await storage.delete(key: 'storeId');
                          //print('Coming Soon');
                          context.push('/coming-soon');
                        }
                      },
                    );
                  } else if (cart.deliveryAddress.streetAddress.isNotEmpty) {
                    //print("1b Branch");

                    deliverToAddress(cart.deliveryAddress.id).then(
                      (resp) async => {
                        if (resp!.deliverable)
                          {
                            await storage
                                .write(
                                    key: 'storeId',
                                    value: resp.storeId.toString())
                                .then((value) => {
                                      storage
                                          .write(
                                              key: 'cartId',
                                              value: resp.cartId.toString())
                                          .then((value) =>
                                              {context.push('/home')})
                                    })
                          }
                        else
                          {
                            await storage.delete(key: 'storeId'),
                            context.push('/coming-soon')
                          }
                      },
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.greenAccent
                          : Colors.grey.shade100,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(15))),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    minVerticalPadding: 12,
                    leading: index == 1
                        ? const Icon(
                            Icons.home,
                            size: 20,
                          )
                        : null, // Icon for current address
                    title: Text(
                      index == 1
                          ? "${addresses[index - 1].streetAddress}, ${addresses[index - 1].lineOne}, ${addresses[index - 1].lineTwo}"
                          //"${cart.deliveryAddress.streetAddress}, ${cart.deliveryAddress.lineOne}, ${cart.deliveryAddress.lineTwo}"
                          : "${addresses[index - 1].streetAddress}, ${addresses[index - 1].lineOne}, ${addresses[index - 1].lineTwo}",
                      style: const TextStyle(fontSize: 16, color: Colors.black),
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
}

// Define other necessary classes/models like Address, etc.

class AddressResponse {
  final Address address;
  final bool deliverable;
  final int storeId;
  final int cartId;

  AddressResponse({
    required this.address,
    required this.deliverable,
    required this.storeId,
    required this.cartId,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    return AddressResponse(
      address: Address.fromJson(AddressResponse._getNestedJson(json)),
      deliverable: json['deliverable'] as bool,
      storeId: json['store_id'] as int,
      cartId: json['cart_id'] as int,
    );
  }

  static Map<String, dynamic> _getNestedJson(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'customer_id': json['customer_id'],
      'street_address': json['street_address'],
      'line_one': json['line_one'],
      'line_two': json['line_two'],
      'city': json['city'],
      'state': json['state'],
      'zip': json['zip'],
      'latitude': json['latitude'],
      'longitude': json['longitude'],
      'created_at': json['created_at'],
    };
  }
}

class DeliverableResponse {
  final bool deliverable;
  final int storeId;
  final int cartId;

  DeliverableResponse(
      {required this.deliverable, required this.storeId, required this.cartId});

  factory DeliverableResponse.fromJson(Map<String, dynamic> json) {
    return DeliverableResponse(
      deliverable: json['deliverable'] as bool,
      storeId: json['store_id'] as int,
      cartId: json['cart_id'] as int,
    );
  }
}
