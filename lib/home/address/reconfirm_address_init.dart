import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/home/address/select/select.dart';
import 'package:provider/provider.dart';

class ReconfirmAddressInit extends StatefulWidget {
  final LatLng coordinates;
  final String lineOneAddress;
  final String lineTwoAddress;
  final String locality;
  final String sublocality;
  final String thoroughfare;
  final String subthoroughfare;
  final String administrativeArea;
  final String subAdministrativeArea;
  final String postalCode;

  const ReconfirmAddressInit(
      {Key? key,
      required this.coordinates,
      required this.lineOneAddress,
      required this.lineTwoAddress,
      required this.locality,
      required this.sublocality,
      required this.thoroughfare,
      required this.subthoroughfare,
      required this.administrativeArea,
      required this.subAdministrativeArea,
      required this.postalCode})
      : super(key: key);
  @override
  State<ReconfirmAddressInit> createState() => _ReconfirmAddressInitState();
}

class _ReconfirmAddressInitState extends State<ReconfirmAddressInit> {
  final _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  late CameraPosition
      _kGooglePlex; // Declare _kGooglePlex here without initializing
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Initialize _kGooglePlex here using widget.coordinates
    _kGooglePlex = CameraPosition(
      target: widget.coordinates,
      zoom: 16,
    );
    _markers.add(
      Marker(
        markerId: const MarkerId("selected-location"),
        position: widget.coordinates,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartModel = context.watch<CartModel>();
    print(
        "Widget Variables: coordinates${widget.coordinates} lineone ${widget.lineOneAddress} linetwo ${widget.lineTwoAddress} local ${widget.locality} postal ${widget.postalCode} sublocal ${widget.sublocality} thoroughfare ${widget.thoroughfare} subthour ${widget.subthoroughfare} admin ${widget.administrativeArea} subadmin ${widget.subAdministrativeArea}");

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldMessengerKey, // Use this key for ScaffoldMessenger
        appBar: AppBar(
          title: const Text(
            'Add Address Details',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.25,
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.height * 0.03,
                ),
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 2.0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  // Use ClipRRect to clip the child widget with rounded corners
                  borderRadius: const BorderRadius.all(Radius.circular(
                      15)), // Match the parent Container's borderRadius
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _kGooglePlex,
                    markers: _markers, // Use the _markers set here
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    // ignore: prefer_collection_literals
                    gestureRecognizers: Set(), // Disable gesture recognizers
                    zoomGesturesEnabled: false, // Disable zoom gestures
                    scrollGesturesEnabled: false, // Disable scroll gestures
                    rotateGesturesEnabled: false, // Disable rotate gestures
                    tiltGesturesEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  left: MediaQuery.of(context).size.height * 0.03,
                  right: MediaQuery.of(context).size.height * 0.03,
                  top: MediaQuery.of(context).size.height * 0.02,
                ),
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                          color: Colors.deepPurpleAccent, width: 2),
                      borderRadius: BorderRadius.circular(35),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('change'),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.height * 0.02,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                child: FormBuilder(
                  key: _formKey,
                  child: Column(
                    children: [
                      FormBuilderTextField(
                        name: 'flatBuildingName',
                        decoration: InputDecoration(
                          labelText: 'House Name, No. & Floor',
                          hintText: '',
                          filled: true, // Enable filling of the input
                          fillColor: Colors.grey[
                              200], // Set light grey color as the background
                          border: OutlineInputBorder(
                            // Define the border
                            borderRadius: BorderRadius.circular(
                                15.0), // Circular rounded border
                            borderSide: BorderSide.none, // No border side
                          ),
                        ),
                        initialValue: '',
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 25),
                      FormBuilderTextField(
                        name: 'lineOneAddress',
                        decoration: InputDecoration(
                          labelText: 'Landmark (optional)',
                          filled: true, // Enable filling of the input
                          fillColor: Colors.grey[
                              200], // Set light grey color as the background
                          border: OutlineInputBorder(
                            // Define the border
                            borderRadius: BorderRadius.circular(
                                15.0), // Circular rounded border
                            borderSide: BorderSide.none, // No border side
                          ),
                        ),
                        initialValue: widget.lineOneAddress,
                        validator: _requiredValidator,
                        readOnly: false,
                      ),
                      const SizedBox(height: 25),
                      FormBuilderTextField(
                        name: 'lineTwoAddress',
                        decoration: InputDecoration(
                          labelText: 'Area Name',
                          filled: true, // Enable filling of the input
                          fillColor: Colors.grey[
                              200], // Set light grey color as the background
                          border: OutlineInputBorder(
                            // Define the border
                            borderRadius: BorderRadius.circular(
                                15.0), // Circular rounded border
                            borderSide: BorderSide.none, // No border side
                          ),
                        ),
                        initialValue: widget.lineTwoAddress,
                        readOnly: false,
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.saveAndValidate()) {
                            var formData = _formKey.currentState!.value;
                            if (formData['flatBuildingName'].isEmpty) {
                              _scaffoldMessengerKey.currentState!.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please fill out the Flat No. and Building Name.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            bool isSuccess =
                                await cartModel.postDeliveryAddress(
                                    formData['flatBuildingName'],
                                    formData['lineOneAddress'],
                                    formData['lineTwoAddress'],
                                    widget.subAdministrativeArea.isEmpty
                                        ? widget.locality
                                        : widget.subAdministrativeArea,
                                    widget.postalCode,
                                    widget.administrativeArea.isEmpty
                                        ? ""
                                        : widget.administrativeArea,
                                    widget.coordinates.latitude,
                                    widget.coordinates.longitude);

                            if (isSuccess) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AddressSelectionWidget(
                                          flag: true,
                                        )),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.height * 0.03,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          "Save Address",
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
