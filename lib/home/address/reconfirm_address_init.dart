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

  @override
  Widget build(BuildContext context) {
    final cartModel = context.watch<CartModel>();
    print('locality: ${widget.locality}');

    return Scaffold(
      key: _scaffoldMessengerKey, // Use this key for ScaffoldMessenger
      appBar: AppBar(
        title: const Text('Address Details'),
        surfaceTintColor: Colors.white,
        centerTitle: true,
      ),
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            FormBuilderTextField(
              name: 'flatBuildingName',
              decoration: InputDecoration(
                labelText: 'Flat No. and Building Name',
                hintText: 'Flat - Building Name',
                filled: true, // Enable filling of the input
                fillColor:
                    Colors.grey[200], // Set light grey color as the background
                border: OutlineInputBorder(
                  // Define the border
                  borderRadius:
                      BorderRadius.circular(10.0), // Circular rounded border
                  borderSide: BorderSide.none, // No border side
                ),
              ),
              initialValue: '',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 25),
            FormBuilderTextField(
              name: 'landmark',
              decoration: InputDecoration(
                labelText: 'Landmark (optional)',
                hintText: 'Landmark (optional)',
                filled: true, // Enable filling of the input
                fillColor:
                    Colors.grey[200], // Set light grey color as the background
                border: OutlineInputBorder(
                  // Define the border
                  borderRadius:
                      BorderRadius.circular(10.0), // Circular rounded border
                  borderSide: BorderSide.none, // No border side
                ),
              ),
              initialValue: '',
            ),
            const SizedBox(height: 25),
            FormBuilderTextField(
              name: 'locality',
              decoration: InputDecoration(
                labelText: 'Locality',
                hintText: 'Optional',
                filled: true, // Enable filling of the input
                fillColor:
                    Colors.grey[200], // Set light grey color as the background
                border: OutlineInputBorder(
                  // Define the border
                  borderRadius:
                      BorderRadius.circular(10.0), // Circular rounded border
                  borderSide: BorderSide.none, // No border side
                ),
              ),
              initialValue:
                  '${widget.subthoroughfare}, ${widget.subthoroughfare}, ${widget.sublocality}',
              readOnly: true,
            ),
            const SizedBox(height: 25),
            FormBuilderTextField(
              name: 'lineOneAddress',
              decoration: InputDecoration(
                labelText: 'Line Address One',
                filled: true, // Enable filling of the input
                fillColor:
                    Colors.grey[200], // Set light grey color as the background
                border: OutlineInputBorder(
                  // Define the border
                  borderRadius:
                      BorderRadius.circular(10.0), // Circular rounded border
                  borderSide: BorderSide.none, // No border side
                ),
              ),
              initialValue: widget.lineOneAddress,
              readOnly: true,
            ),
            const SizedBox(height: 25),
            FormBuilderTextField(
              name: 'lineTwoAddress',
              decoration: InputDecoration(
                labelText: 'Line Address Two',
                filled: true, // Enable filling of the input
                fillColor:
                    Colors.grey[200], // Set light grey color as the background
                border: OutlineInputBorder(
                  // Define the border
                  borderRadius:
                      BorderRadius.circular(10.0), // Circular rounded border
                  borderSide: BorderSide.none, // No border side
                ),
              ),
              initialValue: widget.lineTwoAddress,
              readOnly: true,
            ),
            const SizedBox(height: 25),
            FormBuilderTextField(
              name: 'zipCode',
              decoration: InputDecoration(
                labelText: 'Pin Code',
                hintText: 'Optional',
                filled: true, // Enable filling of the input
                fillColor:
                    Colors.grey[200], // Set light grey color as the background
                border: OutlineInputBorder(
                  // Define the border
                  borderRadius:
                      BorderRadius.circular(10.0), // Circular rounded border
                  borderSide: BorderSide.none, // No border side
                ),
              ),
              initialValue: widget.postalCode,
              readOnly: true,
            ),
            const SizedBox(height: 50),
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
                  bool isSuccess = await cartModel.postDeliveryAddress(
                      formData['flatBuildingName'],
                      formData['lineOneAddress'],
                      formData['lineTwoAddress'],
                      formData['city'],
                      formData['zipCode'],
                      formData['stateName'],
                      widget.coordinates.latitude,
                      widget.coordinates.longitude);

                  if (isSuccess) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const AddressSelectionWidget(
                                flag: true,
                              )),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EE),
                padding:
                    const EdgeInsets.symmetric(horizontal: 65, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Add Address",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
