import 'package:flutter/material.dart';
import 'package:pronto/cart/address/screen/confirm_address.dart';
import 'package:pronto/cart/address/worker/debouncer.dart';
import 'package:pronto/cart/address/worker/location_list_tile.dart';
import 'package:pronto/cart/address/worker/network_utility.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/home/address/confirm_address_screen.dart';
import 'package:pronto/utils/constants.dart';

import 'package:pronto/home/models/place_auto_complete_response.dart';
import 'package:pronto/home/models/prediction_auto_complete.dart';
import 'package:provider/provider.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<PredictionAutoComplete> placePredictions = [];
  //final Logger _logger = Logger();

  final _debouncer = Debouncer(milliseconds: 500); // Adjust the delay as needed

  void placeAutocomplete(String query) async {
    //print("Entered placeAutocomplete");
    //print("ApiKey: $apiKey");

    Uri uri =
        Uri.https("maps.googleapis.com", "maps/api/place/autocomplete/json", {
      "input": query,
      "key": modApikey,
    });

    print('Api Key: $modApikey');

    await Future.delayed(const Duration(seconds: 2));

    String? response = await NetworkUtility.fetchUrl(uri);

    if (response != null) {
      PlaceAutoCompleteResponse result =
          PlaceAutoCompleteResponse.parseAutocompleteResult(response);

      String? predictions = result.predictions?[0].description;
      print("Prediction[0].description  $predictions");

      if (result.predictions != null) {
        setState(() {
          placePredictions = result.predictions!;
          //print("PlacePredictions.length  ${placePredictions.length}");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Address"),
      ),
      body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (value) => {
                      _debouncer.run(() {
                        placeAutocomplete(value);
                      })
                    }, //placeAutocomplete(value)},
                    decoration: const InputDecoration(
                      hintText: 'Enter Your Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyCart(),
                        ),
                      ); // Close the address bottom sheet
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      fixedSize: const Size(double.infinity, 40),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    child: const Text('Current Location'),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.75, // Adjust as needed
                  child: ListView.builder(
                    itemCount: placePredictions.length,
                    itemBuilder: (context, index) {
                      //print("Description: ${placePredictions[index].description}");
                      return LocationListTile(
                        location: placePredictions[index].description!,
                        press: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmAddressInit(
                                  placeId: placePredictions[index].placeId!),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
