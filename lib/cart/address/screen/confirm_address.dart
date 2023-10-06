import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:pronto/utils/constants.dart';

class ConfirmAddress extends StatefulWidget {
  final String placeId;

  const ConfirmAddress({Key? key, required this.placeId}) : super(key: key);

  @override
  State<ConfirmAddress> createState() => _ConfirmAddressState();
}

class _ConfirmAddressState extends State<ConfirmAddress> {
  final Completer<GoogleMapController> _googleMapController = Completer();
  CameraPosition? _cameraPosition;
  late LatLng _defaultLatLng;
  late LatLng _draggedLatlng;
  String _draggedAddress = "";
  final String placedApiKey = apiKey;

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
    _setInitialMapLocationFromPlaceId();
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
            LatLng(_defaultLatLng.latitude, _defaultLatLng.longitude));
        print("LatLang $_defaultLatLng");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Address"),
      ),
      body: _buildBody(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "reset",
                onPressed: () {
                  _gotoUserCurrentPosition();
                },
                backgroundColor: const Color.fromARGB(255, 188, 234, 255),
                child: const Text("Reset"),
              ),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "location",
                onPressed: () {
                  _gotoUserCurrentPosition();
                },
                backgroundColor: const Color.fromARGB(255, 188, 234, 255),
                child: const Icon(
                  Icons.location_on,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.1,
                child: FloatingActionButton(
                  heroTag: "confirm",
                  onPressed: () {
                    _gotoUserCurrentPosition();
                  },
                  child: const Center(
                    child: Text(
                      "Confirm Address",
                      style: TextStyle(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Stack(children: [_getMap(), _getCustomPin(), _showDraggedAddress()]);
  }

  Widget _showDraggedAddress() {
    return SafeArea(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: const BoxDecoration(
          color: Colors.deepPurpleAccent,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
        ),
        child: Center(
            child: Text(
          _draggedAddress,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        )),
      ),
    );
  }

  Widget _getMap() {
    return GoogleMap(
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
      child: SizedBox(
        width: 150,
        child: Lottie.asset("assets/pin.json"),
      ),
    );
  }

  Future _getAddress(LatLng position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark address = placemarks[0];
    String addresStr =
        "${address.street}, ${address.locality}, ${address.administrativeArea}, ${address.country}";
    setState(() {
      _draggedAddress = addresStr;
    });
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
      print("user don't enable location permission");
    }

    locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied) {
        print("user denied location permission");
      }
    }

    if (locationPermission == LocationPermission.deniedForever) {
      print("user denied permission forever");
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
  }

  Future<LatLng?> getLocationFromPlaceId(String placeId) async {
    print("PlaceId: $placeId");
    var url =
        "https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=$modapikey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      //print("Response=200 ${response.body}");
      final data = jsonDecode(response.body);

      if (data["status"] == "OK") {
        final lat = data["results"][0]["geometry"]["location"]["lat"];
        final lng = data["results"][0]["geometry"]["location"]["lng"];
        print("Lat $lat Long $lng");
        return LatLng(lat, lng);
      }
    } else {
      print("Response $response");
    }
    return null;
  }
}
