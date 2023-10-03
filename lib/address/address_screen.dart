import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/home/components/location_list_tile.dart';
import 'package:pronto/home/components/network_utility.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/home/models/place_auto_complete_response.dart';
import 'package:pronto/home/models/prediction_auto_complete.dart';
import 'package:pronto/address/debouncer.dart';
import 'package:provider/provider.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<PredictionAutoComplete> placePredictions = [];
  final Logger _logger = Logger();

  final _debouncer =
      Debouncer(milliseconds: 1000); // Adjust the delay as needed

  void placeAutocomplete(String query) async {
    _logger.e("Entered placeAutocomplete");
    _logger.e("ApiKey: $apiKey");

    Uri uri =
        Uri.https("maps.googleapis.com", "maps/api/place/autocomplete/json", {
      "input": query,
      "key": apiKey,
    });

    await Future.delayed(const Duration(seconds: 2));

    String? response = await NetworkUtility.fetchUrl(uri);

    if (response != null) {
      PlaceAutoCompleteResponse result =
          PlaceAutoCompleteResponse.parseAutocompleteResult(response);

      String? predictions = result.predictions?[0].description;
      _logger.e("Prediction[0].description  $predictions");

      if (result.predictions != null) {
        setState(() {
          placePredictions = result.predictions!;
          _logger.e("PlacePredictions.length  ${placePredictions.length}");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 5),
            const Text(
              'Set Address',
              style: TextStyle(fontSize: 20),
            ),
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
                          builder: (context) => const MyHomePage(
                              title:
                                  'Pronto'))); // Close the address bottom sheet
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
              height:
                  MediaQuery.of(context).size.height * 0.4, // Adjust as needed
              child: ListView.builder(
                itemCount: placePredictions.length,
                itemBuilder: (context, index) {
                  return LocationListTile(
                    location: placePredictions[index].description!,
                    press: () {
                      /*
                      cart.deliveryAddress = Address(
                          //placeId: placePredictions[index].placeId!,
                          lineOne: placePredictions[index]
                              .structuredFormatting!
                              .mainText!,
                          lineTwo: placePredictions[index]
                              .structuredFormatting!
                              .secondaryText!);
                      Navigator.of(context).pop();
                      */
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
