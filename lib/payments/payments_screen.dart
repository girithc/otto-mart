import 'package:flutter/material.dart';
import 'package:pronto/order/place_order_screen.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

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
            'Pronto Payments',
            style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        elevation: 4.0,
        backgroundColor: //Colors.deepPurpleAccent.shade100,
            Colors.white,
        foregroundColor: Colors.deepPurple,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: const Center(
        child: Text("Payment Gateway"),
      ),
      floatingActionButton: BottomAppBar(
        height: MediaQuery.of(context).size.height * 0.15,
        child: Container(
          padding: const EdgeInsets.only(left: 20),
          alignment: Alignment.center,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaceOrder(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              textStyle: Theme.of(context).textTheme.titleLarge,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.electric_bike_outlined),
                SizedBox(width: 10),
                Text('Pay'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
