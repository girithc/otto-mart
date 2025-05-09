import 'package:flutter/material.dart';
import 'package:pronto/cart/cart_screen.dart';

// Assuming CartScreen is defined elsewhere in your project

class RefundsPage extends StatefulWidget {
  const RefundsPage({super.key});

  @override
  State<RefundsPage> createState() => _RefundsPageState();
}

class _RefundsPageState extends State<RefundsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refunds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to CartScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      MyCart()), // Make sure CartScreen is defined and imported
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Payment Not Complete',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8), // Adds space between the lines
            const Text(
              'Any amount deducted will be refunded within 24 to 72 hours.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24), // Adds space before the button
            ElevatedButton(
              onPressed: () {
                // Navigate back to CartScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MyCart()), // Make sure CartScreen is defined and imported
                );
              },
              child: const Text('Go to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
