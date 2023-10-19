import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pronto/cart/cart.dart';
import 'package:provider/provider.dart';

class ReconfirmAddressInit extends StatefulWidget {
  final LatLng coordinates;
  final String lineOneAddress;
  final String lineTwoAddress;

  const ReconfirmAddressInit({
    Key? key,
    required this.coordinates,
    required this.lineOneAddress,
    required this.lineTwoAddress,
  }) : super(key: key);
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

    return Scaffold(
      key: _scaffoldMessengerKey, // Use this key for ScaffoldMessenger
      appBar: AppBar(title: const Text('Address Details')),
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            FormBuilderTextField(
              name: 'flatBuildingName',
              decoration: const InputDecoration(
                labelText: 'Flat No. and Building Name',
                hintText: 'Flat - Building Name',
              ),
              initialValue: '',
              validator: _requiredValidator,
            ),
            FormBuilderTextField(
              name: 'lineOneAddress',
              decoration: const InputDecoration(
                labelText: 'Line Address One',
              ),
              initialValue: widget.lineOneAddress,
              enabled: false, // Makes the field uneditable
            ),
            FormBuilderTextField(
              name: 'lineTwoAddress',
              decoration: const InputDecoration(
                labelText: 'Line Address Two',
              ),
              initialValue: widget.lineTwoAddress,
              enabled: false, // Makes the field uneditable
            ),
            FormBuilderTextField(
              name: 'city',
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Optional',
              ),
            ),
            FormBuilderTextField(
              name: 'zipCode',
              decoration: const InputDecoration(
                labelText: 'Zip Code',
                hintText: 'Optional',
              ),
            ),
            FormBuilderTextField(
              name: 'stateName',
              decoration: const InputDecoration(
                labelText: 'State',
                hintText: 'Optional',
              ),
            ),
            FormBuilderTextField(
              name: 'coordinates',
              decoration: const InputDecoration(
                labelText: 'Coordinates',
              ),
              initialValue:
                  "Lat: ${widget.coordinates.latitude} , Long: ${widget.coordinates.longitude}",
              enabled: false, // Makes the field uneditable
            ),
          ],
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.1,
          child: FloatingActionButton(
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
                  for (int i = 0; i < 3; i++) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      // If you cannot pop any more, break the loop
                      break;
                    }
                  }
                }
              }
            },
            child: const Text(
              'Add Address',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
