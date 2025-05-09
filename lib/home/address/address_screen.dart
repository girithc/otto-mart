import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pronto/cart/address/worker/debouncer.dart';
import 'package:pronto/cart/address/worker/location_list_tile.dart';
import 'package:pronto/cart/address/worker/network_utility.dart';
import 'package:location/location.dart';
import 'package:app_settings/app_settings.dart'; // Make sure to add app_settings to your pubspec.yaml

import 'package:pronto/home/address/confirm_address_screen.dart';
import 'package:pronto/utils/constants.dart';

import 'package:pronto/home/models/place_auto_complete_response.dart';
import 'package:pronto/home/models/prediction_auto_complete.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<PredictionAutoComplete> placePredictions = [];
  //final Logger _logger = Logger();

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  bool _isLocationEnabled = false;
  bool _locationPermissionDeniedForever = false; // Define the variable here

  final Location location = Location();

  @override
  void initState() {
    super.initState();
    _checkLocationServiceAndPermission(); // Check both service and permission
  }

  void _checkLocationServiceAndPermission() async {
    bool _serviceEnabled = await location.serviceEnabled();
    LocationPermission _permission = await Geolocator.checkPermission();

    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
    }

    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
    }

    setState(() {
      _isLocationEnabled = _serviceEnabled &&
          _permission != LocationPermission.denied &&
          _permission != LocationPermission.deniedForever;
      _locationPermissionDeniedForever =
          _permission == LocationPermission.deniedForever;
      print("Location Disabled $_isLocationEnabled");
    });
  }

  void _checkLocationService() async {
    Location location = new Location();
    bool _serviceEnabled;
    // Check if the location service is enabled
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      // If not, request to enable it
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        // If the user refuses to enable the location, update the UI accordingly
        setState(() {
          _isLocationEnabled = false;
        });
        return;
      }
    }
    // If location service is enabled, update the state
    setState(() {
      _isLocationEnabled = true;
    });
  }

  Future<void> _requestLocationService() async {
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
        AppSettings.openAppSettings();
      } else if (permission == LocationPermission.deniedForever) {
        AppSettings.openAppSettings();
      } else {
        setState(() {
          _isLocationEnabled = true;
          _locationPermissionDeniedForever = false;
        });
      }
    }
    if (permission == LocationPermission.deniedForever) {
      AppSettings.openAppSettings();
    }

    // Location service is enabled
    // You can proceed with obtaining the location or updating your state as necessary
  }

  final _debouncer = Debouncer(milliseconds: 100); // Adjust the delay as needed

  void placeAutocomplete(String query) async {
    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/autocomplete/json",
      {
        "input": query,
        "key": modApikey,
        // Add the components parameter with country code for India
        "components": "country:IN",
      },
    );

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
      setState(() {
        _isLocationEnabled = false;
        _locationPermissionDeniedForever = true;
      });
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
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            "Enter Address",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            color: Colors.white,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _kGooglePlex,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Position position = await _determinePosition();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmAddressInit(
                                placeId: '',
                                paramLatLng: LatLng(
                                    position.latitude, position.longitude),
                              ),
                            ),
                          );
                          // Close the address bottom sheet
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 20, horizontal: 20),
                          backgroundColor: Color.fromARGB(255, 255, 235, 235),
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Icon(
                                Icons.my_location_outlined,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                            ),
                            _isLocationEnabled ||
                                    !_locationPermissionDeniedForever
                                ? SizedBox(
                                    width: 10,
                                  )
                                : SizedBox.shrink(),
                            _isLocationEnabled ||
                                    !_locationPermissionDeniedForever
                                ? Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Location',
                                          style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  )
                                : Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Location',
                                          style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          'Enable your current \nlocation for better services',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54),
                                        )
                                      ],
                                    ),
                                  ),
                            _isLocationEnabled ||
                                    !_locationPermissionDeniedForever
                                ? Container()
                                : Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 2, vertical: 5),
                                          backgroundColor: Colors.white,
                                          surfaceTintColor: Colors.white,
                                          // Define the shape and border of the button
                                          shape: RoundedRectangleBorder(
                                            // Less roundish borders
                                            borderRadius: BorderRadius.circular(
                                                10), // You can adjust the radius to make it less/more round
                                            // Red accent border color
                                            side: BorderSide(
                                                color: Colors.redAccent,
                                                width:
                                                    0.5), // You can adjust the width as needed
                                          ),
                                        ),
                                        onPressed: () {
                                          _requestLocationService();
                                        },
                                        child: Text(
                                          'Enable',
                                          style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold),
                                        )),
                                  )
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: TextField(
                        onChanged: (value) => {
                          _debouncer.run(() {
                            placeAutocomplete(value);
                          })
                        },
                        //placeAutocomplete(value)},
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 25, vertical: 20),
                          hintText: 'Enter Your Address',
                          hintStyle: TextStyle(
                            color: Colors.black,
                          ),
                          focusColor: Colors.white,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 255, 135,
                                    175)), // Make the default border transparent
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 255, 135,
                                    175)), // Make the border transparent when the TextField is enabled but not focused
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(
                            left: 10, right: 10, bottom: 30),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        // Adjust as needed
                        child: ListView.builder(
                          itemCount: placePredictions.length,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                borderRadius:
                                    index == (placePredictions.length - 1)
                                        ? const BorderRadius.only(
                                            bottomLeft: Radius.circular(15),
                                            bottomRight: Radius.circular(15))
                                        : const BorderRadius.all(
                                            Radius.circular(0)),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ConfirmAddressInit(
                                        placeId:
                                            placePredictions[index].placeId!,
                                      ),
                                    ),
                                  );
                                },
                                horizontalTitleGap: 10,
                                leading: Icon(
                                  Icons
                                      .location_city_outlined, // Replace with the desired icon
                                  color: Colors
                                      .pinkAccent, // Replace with the desired color
                                ),
                                title: Text(
                                  placePredictions[index]
                                      .structuredFormatting!
                                      .mainText!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Text(
                                    placePredictions[index].description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
