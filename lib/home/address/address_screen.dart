import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  final _debouncer = Debouncer(milliseconds: 100); // Adjust the delay as needed

  void placeAutocomplete(String query) async {
    Uri uri =
        Uri.https("maps.googleapis.com", "maps/api/place/autocomplete/json", {
      "input": query,
      "key": modApikey,
    });

    //print('Api Key: $modApikey');

    await Future.delayed(const Duration(milliseconds: 1000));

    String? response = await NetworkUtility.fetchUrl(uri);

    if (response != null) {
      PlaceAutoCompleteResponse result =
          PlaceAutoCompleteResponse.parseAutocompleteResult(response);

      String? predictions = result.predictions?[0].description;
      //print("Prediction[0].description  $predictions");

      if (result.predictions != null) {
        setState(() {
          placePredictions = result.predictions!;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permisssions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition();
    return position;
  }

  @override
  Widget build(BuildContext context) {
    //var cart = context.watch<CartModel>();
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.black,
        title: const Text(
          "Delivery Address",
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            color: Colors.white,
            width: MediaQuery.of(context).size.width * 0.95,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 18),
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
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      Position position = await _determinePosition();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmAddressInit(
                            placeId: '',
                            paramLatLng:
                                LatLng(position.latitude, position.longitude),
                          ),
                        ),
                      );
                      // Close the address bottom sheet
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      fixedSize: const Size(double.infinity, 45),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.near_me_outlined),
                        SizedBox(
                          width: 10,
                        ),
                        Text('Current Location'),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.75, // Adjust as needed
                  child: ListView.builder(
                    itemCount: placePredictions.length,
                    itemBuilder: (context, index) {
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
