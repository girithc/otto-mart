import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pronto/home/home_screen.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
    // Fetch orders when the widget is initialized
    fetchOrders();
  }

  // Function to fetch orders based on customer ID
  Future<void> fetchOrders() async {
    const storage = FlutterSecureStorage();
    String? customerId = await storage.read(key: 'customerId');

    // Replace the following line with your actual logic to fetch orders
    // For demonstration purposes, a simple list is used here.
    orders = [
      Order(
          current: true,
          date: '11/10/2023',
          address: 'radha kunj',
          paymentType: 'cash',
          paid: false),
      Order(
          current: false,
          date: '05/10/2023',
          address: 'laxmi kunj',
          paymentType: 'credit',
          paid: true),
      Order(
          current: false,
          date: '05/10/2023',
          address: 'laxmi kunj',
          paymentType: 'credit',
          paid: true),
      Order(
          current: false,
          date: '01/10/2023',
          address: 'laxmi kunj',
          paymentType: 'cash',
          paid: true),
      Order(
          current: false,
          date: '01/08/2023',
          address: 'hira kunj',
          paymentType: 'upi',
          paid: true),
    ];

    setState(() {}); // Update the UI after fetching orders
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurpleAccent,
        title: InkWell(
          child: ShaderMask(
            shaderCallback: (bounds) => const RadialGradient(
              center: Alignment.topLeft,
              radius: 1.0,
              colors: [Colors.white, Colors.white70],
              tileMode: TileMode.mirror,
            ).createShader(bounds),
            child: const Text(
              'Otto Mart',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MyHomePage(
                  title: 'Otto Mart',
                ),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Use a ListView.builder to dynamically create the order containers
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.16,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: orders[index].paid!
                            ? Colors.indigoAccent.withOpacity(0.5)
                            : Colors.deepOrangeAccent.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Paid: ${orders[index].paid.toString()}',
                          style: GoogleFonts.robotoMono(fontSize: 18),
                        ),
                        Text(
                          orders[index].address!,
                          style: GoogleFonts.robotoMono(fontSize: 18),
                        ),
                        Text(
                          orders[index].date!,
                          style: GoogleFonts.robotoMono(fontSize: 18),
                        ),
                        Text(
                          orders[index].paymentType!,
                          style: GoogleFonts.robotoMono(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Add more containers or widgets if needed
          ],
        ),
      ),
    );
  }
}

class Order {
  bool? current;
  String? date;
  String? address;
  String? paymentType;
  bool? paid;

  Order({this.current, this.date, this.address, this.paymentType, this.paid});
}
