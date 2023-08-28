import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:master/item-detail/api.dart';
import 'package:master/item-detail/item-detail.dart';

class ItemDetails extends StatefulWidget {
  const ItemDetails({required this.itemId, required this.itemName, super.key});

  final int itemId;
  final String itemName;

  @override
  State<ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  bool isDataFetched = false; // Flag to indicate whether data is fetched
  final ItemDetailApiClient apiClient =
      ItemDetailApiClient('https://localhost:3000');
  List<Item> items = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Create an updated item based on form inputs
    UpdateItem updatedItem = UpdateItem(
        id: widget.itemId,
        name: _nameController.text,
        price: int.parse(_priceController.text),
        stockQuantity: int.parse(_stockQuantityController.text),
        categoryId: items[0].categoryId);

    try {
      await apiClient
          .editItem(updatedItem); // Call your updateItem function here

      // Optionally, update the local state to reflect the changes
      setState(() {
        //items[0] = updatedItem.name;
      });

      // Handle success, show a toast, navigate back, etc.
    } catch (error) {
      // Handle error, show an error message, etc.
    }
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockQuantityController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchItem();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  Future<void> fetchItem() async {
    try {
      final fetchedItem = await apiClient.fetchItem(widget.itemId);
      setState(() {
        print(
            "Fetched Item ${fetchedItem.name}, ${fetchedItem.price}, ${fetchedItem.stockQuantity}");
        //throw Exception("Debug");
        items.add(fetchedItem);
        _nameController.text = fetchedItem.name;
        _priceController.text = fetchedItem.price.toString();
        _stockQuantityController.text = fetchedItem.stockQuantity.toString();
        isDataFetched = true; // Mark data as fetched
      });
    } catch (err) {
      //Handle Error
      setState(() {
        items = [];
      });
      print('(itemdetails)fetchItems error $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4.0,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          widget.itemName,
          style: const TextStyle(
              color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Center(
          child: isDataFetched
              ? Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.person),
                          hintText: 'Enter Item Name',
                          labelText: 'Item Name',
                        ),
                        //initialValue: items[0].name,
                      ),
                      TextFormField(
                        controller: _stockQuantityController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.shopping_bag_outlined),
                          hintText: 'Enter Stock Quantity',
                          labelText: 'Stock Quantity',
                        ),
                        //initialValue: items[0].stockQuantity.toString(),
                      ),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.attach_money_outlined),
                          hintText: 'Enter Item Price',
                          labelText: 'Item Price',
                        ),
                        //initialValue: items[0].price.toString(),
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          icon: Icon(Icons.calendar_today),
                          hintText: 'Enter Created Date',
                          labelText: 'Created Date',
                        ),
                        initialValue: items[0].createdAt,
                        enabled: false, // Make the field read-only
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          icon: Icon(Icons.person_2_outlined),
                          hintText: 'Enter Created By',
                          labelText: 'Created By',
                        ),
                        initialValue: items[0].createdBy.toString(),
                        enabled: false, // Make the field read-only
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          icon: Icon(Icons.person_2_outlined),
                          hintText: 'Enter Image Link',
                          labelText: 'Image',
                        ),
                        enabled: false,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 150.0, top: 40.0),
                        child: ElevatedButton(
                          onPressed: _saveItem,
                          child: const Text('Save'),
                        ),
                      ),
                      const ImageUpload(),
                    ],
                  ),
                )
              : const CircularProgressIndicator(), // Show a loading indicator when data is being fetched
        ),
      ),
    );
  }
}

class ImageUpload extends StatefulWidget {
  const ImageUpload({super.key});

  @override
  State<ImageUpload> createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  File? _image;
  Uint8List? _imageBytes;
  final picker = ImagePicker();
  CloudApi? api;

  //image picker
  Future getImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemp = File(image.path);

      setState(() {
        _image = imageTemp;
        print('Image: ${_image?.path}');
        _imageBytes = _image?.readAsBytesSync();
      });
    } on Exception catch (e) {
      print('Failed to pick image $e');
    }
  }

  void _saveImage() async {
    final response = await api?.save('test', _imageBytes!);
    print(response?.downloadLink);
  }

  @override
  void initState() {
    super.initState(); // Call the superclass's initState method
    rootBundle.loadString('assets/credentials.json').then((json) {
      api = CloudApi(json);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _image != null
              ? Image.file(_image!, width: 250, height: 250, fit: BoxFit.cover)
              : Image.network('https://picsum.photos/250?image=9'),
          Row(
            children: [
              ElevatedButton(
                  onPressed: () {
                    getImage(ImageSource.gallery);
                  },
                  child: const Text('Add Image')),
              ElevatedButton(
                  onPressed: () {
                    _saveImage();
                  },
                  child: const Text('Save Image')),
            ],
          )
        ],
      ),
    );
  }
}
