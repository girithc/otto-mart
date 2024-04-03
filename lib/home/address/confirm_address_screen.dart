import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:pronto/home/address/reconfirm_address_init.dart';
import 'package:pronto/utils/constants.dart';

class ConfirmAddressInit extends StatefulWidget {
  final String placeId;
  final LatLng? paramLatLng;

  const ConfirmAddressInit({Key? key, required this.placeId, this.paramLatLng})
      : super(key: key);

  @override
  State<ConfirmAddressInit> createState() => _ConfirmAddressInitState();
}

class _ConfirmAddressInitState extends State<ConfirmAddressInit> {
  final Completer<GoogleMapController> _googleMapController = Completer();
  CameraPosition? _cameraPosition;
  late LatLng _defaultLatLng;
  late LatLng _draggedLatlng;
  String _draggedAddress_one = "";
  String _draggedAddress_two = "";
  String _locality = "";
  String _thoroughfare = "";
  String _subthoroughfare = "";
  String _sublocality = "";
  String _postalCode = "";
  String _adminArea = "";
  String _subAdminArea = "";
  bool _isMapAndAddressLoaded = false; // New variable to track loading state

  @override
  void initState() {
    _init();
    //_setInitialMapLocationFromPlaceId();
    super.initState();
  }

  _init() {
    _defaultLatLng = const LatLng(90, 104);
    _draggedLatlng = _defaultLatLng;
    _cameraPosition = CameraPosition(target: _defaultLatLng, zoom: 17.5);
    //_gotoUserCurrentPosition();
    if (widget.placeId.isNotEmpty) {
      _setInitialMapLocationFromPlaceId();
    } else {
      _cameraPosition = CameraPosition(target: widget.paramLatLng!, zoom: 17.5);
      _isMapAndAddressLoaded =
          true; // Map is considered loaded if there's no placeId
    }
  }

  Future<void> _setInitialMapLocationFromPlaceId() async {
    LatLng? initialLatLng = await getLocationFromPlaceId(widget.placeId);
    if (initialLatLng != null) {
      print("Location Found From PlaceID");
      setState(() {
        _defaultLatLng = initialLatLng;
        _draggedLatlng = _defaultLatLng;
        _cameraPosition = CameraPosition(target: _defaultLatLng, zoom: 17.5);
        _gotoSpecificPosition(
                LatLng(_defaultLatLng.latitude, _defaultLatLng.longitude))
            as String;
        print("LatLang $_defaultLatLng");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(MediaQuery.of(context).size.height * 0.135),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Center(
                  child: Text(
                    "Location Information",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade500),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 22, color: Colors.grey),
                        SizedBox(width: 10),
                        Text(
                          "Search",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        color: Colors.white,
        height: MediaQuery.of(context).size.height * 0.208,
        margin: const EdgeInsets.only(bottom: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              minVerticalPadding: 0,
              title: Text(
                _draggedAddress_one,
                maxLines: 2,
                style: const TextStyle(
                  height: 1.3,
                ),
              ),
              subtitle: Text(
                _draggedAddress_two,
                maxLines: 2,
                style: const TextStyle(
                  height: 1.3,
                ),
              ),
              leading: GestureDetector(
                onTap: () {
                  // Action to perform when leading is pressed
                  _gotoUserCurrentPosition();
                },
                child: const CircleAvatar(
                  backgroundColor: Color.fromARGB(255, 27, 0, 101),
                  child: Icon(
                    Icons.restart_alt_sharp,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isMapAndAddressLoaded
                  ? () {
                      // Check if map and address are loaded
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReconfirmAddressInit(
                            coordinates: _draggedLatlng,
                            lineOneAddress: _draggedAddress_one,
                            lineTwoAddress: _draggedAddress_two,
                            locality: _locality,
                            sublocality: _sublocality,
                            thoroughfare: _thoroughfare,
                            subthoroughfare: _subthoroughfare,
                            administrativeArea: _adminArea,
                            subAdministrativeArea: _subAdminArea,
                            postalCode: _postalCode,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent, //const Color(0xFF6200EE),
                padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.height * 0.05,
                    right: MediaQuery.of(context).size.height * 0.05,
                    top: MediaQuery.of(context).size.height * 0.02,
                    bottom: MediaQuery.of(context).size.height * 0.02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                "Confirm & Continue",
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(children: [
      _getMap(),
      _getCustomPin(),
      Positioned(
          bottom: MediaQuery.of(context).size.height * 0.37,
          left: MediaQuery.of(context).size.width * 0.205,
          child: _getCustomPinGuide())
    ]);
  }

  Widget _getMap() {
    return GoogleMap(
      myLocationButtonEnabled: false,
      initialCameraPosition: _cameraPosition!,
      mapType: MapType.normal,
      onCameraIdle: () {
        _getAddress(_draggedLatlng);
      },
      onCameraMove: (cameraPosition) {
        _draggedLatlng = cameraPosition.target;
      },
      onMapCreated: (GoogleMapController controller) {
        if (!_googleMapController.isCompleted) {
          _googleMapController.complete(controller);
        }
      },
    );
  }

  Widget _getCustomPin() {
    return Center(
      child: Container(
        // This padding becomes the border width
        decoration: BoxDecoration(
          color: Colors.transparent, // Container background color
          shape: BoxShape
              .circle, // Ensures the decoration is circular to match the CircleAvatar
          border: Border.all(
            color: Colors.deepPurpleAccent.shade400, // Border color
            width: 2, // Border width
          ),
        ),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 25, // Adjust the radius as needed
          child: Lottie.asset(
            "assets/mark.json",
            width: 200, // Lottie animation width
            height: 200, // Lottie animation height
          ),
        ),
      ),
    );
  }

  Widget _getCustomPinGuide() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.pinkAccent,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2.0,
            spreadRadius: 1.0,
            offset: Offset(0.0, 2.0),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Move the map to adjust\nthe location',
          maxLines: 2,
          textAlign:
              TextAlign.center, // Aligns the text to the center horizontally

          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Future _getAddress(LatLng position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark address = placemarks[0];
    //print("Placemarks: ${placemarks[0].locality} ");
    //print("Address: $address");

    setState(() {
      //_draggedAddress = addressStr;
      _draggedAddress_one = address.street!;
      _draggedAddress_two = address.locality!.isNotEmpty
          ? "${address.subLocality}, ${address.locality}, ${address.administrativeArea}"
          : "${address.administrativeArea}";
      _locality = address.locality!;
      _thoroughfare = address.thoroughfare!;
      _subthoroughfare = address.subThoroughfare!;
      _sublocality = address.subLocality!;
      _postalCode = address.postalCode!;
      _adminArea = address.administrativeArea!;
      _subAdminArea = address.subAdministrativeArea!;
      _isMapAndAddressLoaded = true;
    });
    return null;
  }

  Future _gotoUserCurrentPosition() async {
    //Position currentPosition = await _determineUserCurrentPosition();
    _gotoSpecificPosition(
        LatLng(_defaultLatLng.latitude, _defaultLatLng.longitude));
  }

  Future _gotoSpecificPosition(LatLng position) async {
    GoogleMapController mapController = await _googleMapController.future;
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 17.5)));
    await _getAddress(position);
  }

  Future<Position> _determineUserCurrentPosition() async {
    LocationPermission locationPermission;
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      print("user did not enable location permission");
    }

    locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied) {
        print("user denied location permission");
      }
    }

    if (locationPermission == LocationPermission.deniedForever) {
      print("user denied permission");
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
  }

  Future<LatLng?> getLocationFromPlaceId(String placeId) async {
    //print("PlaceId: $placeId");
    var url =
        "https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=$modApikey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      //print("Response=200 ${response.body}");
      final data = jsonDecode(response.body);

      if (data["status"] == "OK") {
        final lat = data["results"][0]["geometry"]["location"]["lat"];
        final lng = data["results"][0]["geometry"]["location"]["lng"];
        //print("Lat $lat Long $lng");
        return LatLng(lat, lng);
      }
    } else {
      print("Response $response");
    }
    return null;
  }
}
