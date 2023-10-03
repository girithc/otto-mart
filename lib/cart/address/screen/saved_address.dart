import 'package:flutter/material.dart';
import 'package:pronto/cart/address/screen/new_address.dart';
import 'package:pronto/cart/cart.dart';
import 'package:provider/provider.dart';

class SavedAddressScreen extends StatefulWidget {
  const SavedAddressScreen({super.key});

  @override
  State<SavedAddressScreen> createState() => _SavedAddressScreenState();
}

class _SavedAddressScreenState extends State<SavedAddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressModel>().fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes in AddressModel. When AddressModel calls notifyListeners,
    // your UI will rebuild.
    var addressModel = context.watch<AddressModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Address"),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 5),
              ListTile(
                title: const Text(
                  '+ Add New Address',
                  style: TextStyle(color: Colors.deepPurpleAccent),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressScreen(),
                    ),
                  );
                },
              ),
              if (addressModel.addrs
                  .isEmpty) // If addresses are empty show a loading or empty message
                const CircularProgressIndicator(),
              // Use ListView.builder to create a list of ListTiles for each address
              ListView.builder(
                shrinkWrap: true,
                itemCount: addressModel.addrs.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(addressModel.addrs[index]
                      .toString()), // adjust according to your Address object
                  // Add additional properties if needed
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
