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

  const ConfirmAddressInit({Key? key, required this.placeId}) : super(key: key);

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
      bottomNavigationBar: BottomAppBar(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(0),
                minVerticalPadding: 0,
                title: Text(
                  _draggedAddress_one + _draggedAddress_two,
                  style: const TextStyle(height: 1.2),
                ),
                leading: GestureDetector(
                  onTap: () {
                    // Action to perform when leading is pressed
                    _gotoUserCurrentPosition();
                  },
                  child: const CircleAvatar(
                    child: Icon(Icons.location_city_outlined),
                  ),
                ),
                trailing: GestureDetector(
                  onTap: () {
                    // Action to perform when trailing is pressed
                    _gotoUserCurrentPosition();
                  },
                  child: const CircleAvatar(
                    child: Icon(
                      Icons.check,
                      size: 25,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReconfirmAddressInit(
                        coordinates: _defaultLatLng,
                        lineOneAddress: _draggedAddress_one,
                        lineTwoAddress: _draggedAddress_two,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EE),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 65, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Confirm Address",
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          )),
      /*
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0xFF0D47A1),
                              Color(0xFF1976D2),
                              Color(0xFF42A5F5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(8.0),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: () {},
                      child: const Text('Customer Address India'),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0xFF42A5F5),
                              Color(0xFF1976D2),
                              Color(0xFF0D47A1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(8.0),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        _gotoUserCurrentPosition();
                      },
                      child: const Icon(
                        Icons.location_on,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.height * 0.1,
                child: FloatingActionButton(
                  heroTag: "confirm",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReconfirmAddress(
                          coordinates: _defaultLatLng,
                          lineOneAddress: _draggedAddress_one,
                          lineTwoAddress: _draggedAddress_two,
                        ),
                      ),
                    );
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
        ],
      ),
      */
    );
  }

  Widget _buildBody() {
    return Stack(children: [_getMap(), _getCustomPin()]);
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
          _draggedAddress_one + _draggedAddress_two,
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
    print("Placemarks: $placemarks");
    print("Address: $address");

    setState(() {
      //_draggedAddress = addressStr;
      _draggedAddress_one = address.street!;
      _draggedAddress_two = address.locality!.isNotEmpty
          ? "${address.subLocality}, ${address.locality}, ${address.administrativeArea}"
          : "${address.administrativeArea}";
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
        "https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=$modApikey";

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