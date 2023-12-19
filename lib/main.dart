import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:master/item-detail/item-detail.dart';
import 'package:master/pack/checklist.dart';
import 'package:master/stock/add-stock.dart';
import 'package:master/store/stores.dart';
import 'package:master/utils/login/provider/loginProvider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LoginProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scooter Animation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OpeningPageAnimation(),
    );
  }
}

class OpeningPageAnimation extends StatefulWidget {
  const OpeningPageAnimation({Key? key}) : super(key: key);

  @override
  _OpeningPageAnimationState createState() => _OpeningPageAnimationState();
}

class _OpeningPageAnimationState extends State<OpeningPageAnimation> {
  late double _begin;
  late double _end;

  @override
  void initState() {
    super.initState();
    _begin = -0.5;
    _end = 1;
  }

  @override
  Widget build(BuildContext context) {
    // Delayed execution to ensure the context is fully established
    Future.delayed(Duration.zero, () {
      Provider.of<LoginProvider>(context, listen: false).checkLogin(context);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: _begin, end: _end),
          duration: const Duration(seconds: 3, milliseconds: 20),
          builder: (BuildContext context, double position, Widget? child) {
            return Transform.translate(
              offset: Offset(position * MediaQuery.of(context).size.width, 0),
              child: Transform.scale(
                scale: 0.75,
                child: child!,
              ),
            );
          },
          onEnd:
              () {}, // Removed navigation as it's handled in the LoginProvider now
          child: Image.asset('assets/scooter.avif'),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 4.0,
          shadowColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            widget.title,
            style: const TextStyle(
                color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
          ),
        ),
        body: const InventoryManagement()
        //const Stores(), // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement> {
  final ItemDetailApiClient apiClient = ItemDetailApiClient();

  String? _scanBarcodeResult;

  Future<void> scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      setState(() {
        _scanBarcodeResult = barcodeScanRes;
      });
      //_showBarcodeResultDialog(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version';
      // TODO
    }

    if (_scanBarcodeResult != '-1') {
      apiClient.fetchItemFromBarcode(_scanBarcodeResult!).then((success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddStock(item: success)),
        );
      }, onError: (error) {
        // Handle error here if fetchItemFromBarcode fails
        print("Error fetching item: $error");
      });
    }

    if (!mounted) return;
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
      _showBarcodeResultDialog(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version';
      // TODO
    }

    if (!mounted) return;
    setState(() {
      _scanBarcodeResult = barcodeScanRes;
    });
  }

  void _showBarcodeResultDialog(String barcodeResult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scan Result'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Barcode Type: ${barcodeResult.startsWith("http") ? "QR Code" : "Barcode"}'),
                Text('Result: $barcodeResult'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.store_outlined),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_outlined),
          title: const Text('Stores'),
          onTap: () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Stores()),
            )
          },
          shape: ContinuousRectangleBorder(
            side: const BorderSide(width: 1, color: Colors.black),
            borderRadius: BorderRadius.circular(20),
          ),
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.all(10),
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.white, //Colors.white,
            child: Icon(Icons.analytics_outlined),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_outlined),
          title: const Text(
            'Scan Barcode',
            style: TextStyle(color: Colors.black),
          ),
          onTap: scanBarcode,
          shape: ContinuousRectangleBorder(
            side: const BorderSide(width: 1, color: Colors.black),
            borderRadius: BorderRadius.circular(20),
          ),
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.all(10),
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.store_outlined),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_outlined),
          title: const Text('Pack Order'),
          onTap: () => {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const OrderChecklistPage()),
            )
          },
          shape: ContinuousRectangleBorder(
            side: const BorderSide(width: 1, color: Colors.black),
            borderRadius: BorderRadius.circular(20),
          ),
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.all(10),
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.white, //Colors.white,
            child: Icon(Icons.analytics_outlined),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_outlined),
          title: const Text(
            'Item Locator',
            style: TextStyle(color: Colors.black),
          ),
          onTap: scanBarcode,
          shape: ContinuousRectangleBorder(
            side: const BorderSide(width: 1, color: Colors.black),
            borderRadius: BorderRadius.circular(20),
          ),
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.all(10),
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.white, //Colors.white,
            child: Icon(Icons.analytics_outlined),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_outlined),
          title: const Text(
            'Item Reporting',
            style: TextStyle(color: Colors.black),
          ),
          onTap: scanBarcode,
          shape: ContinuousRectangleBorder(
            side: const BorderSide(width: 1, color: Colors.black),
            borderRadius: BorderRadius.circular(20),
          ),
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.all(10),
        ),
      ],
    );
  }
}
