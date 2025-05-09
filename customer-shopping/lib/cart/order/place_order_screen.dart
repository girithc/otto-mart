import 'package:flutter/material.dart';
import 'package:pronto/cart/order/confirmed_order_screen.dart';

class PlaceOrder extends StatelessWidget {
  const PlaceOrder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: ShaderMask(
            shaderCallback: (bounds) => const RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.0,
                    colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                    tileMode: TileMode.mirror)
                .createShader(bounds),
            child: const Text(
              'Otto Mart',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          elevation: 4.0,
          backgroundColor: //Colors.deepPurpleAccent.shade100,
              Colors.white,
          foregroundColor: Colors.deepPurple,
          shadowColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [TextCycler(), LinearProgressIndicator()],
        ));
  }
}

class TextCycler extends StatefulWidget {
  const TextCycler({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TextCyclerState createState() => _TextCyclerState();
}

class _TextCyclerState extends State<TextCycler> {
  final List<String> textList = [
    'Processing Payment',
    'Contacting Delivery Partner',
    'Order Confirmed',
    ''
  ];
  int currentIndex = 0;
  bool disposed = false;

  @override
  void initState() {
    super.initState();
    startCycling();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  void startCycling() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!disposed) {
        setState(() {
          currentIndex = (currentIndex + 1) % textList.length;
        });
        if (currentIndex == textList.length - 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => OrderConfirmed(
                      newOrder: true,
                    )),
          );
        } else {
          startCycling();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          textList[currentIndex],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
        ),
      ],
    );
  }
}
