import 'package:flutter/material.dart';

/// Flutter code sample for [Card].

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pronto',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [CartItems(), CartSummary()],
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () {
          // Add your button logic here
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(8.0), // Adjust the value for squareness
          ),
          backgroundColor: const Color.fromARGB(255, 217, 39, 233),
          padding: const EdgeInsets.all(16.0), // Set the background color
        ),
        child: const Text(
          'Go To Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class CartItems extends StatefulWidget {
  const CartItems({super.key});

  @override
  State<CartItems> createState() => _CartItemsState();
}

class _CartItemsState extends State<CartItems> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              width: 350, // Set the desired width for the Card
              child: Card(
                color: Colors.white,
                elevation: 5.0,
                shadowColor: Colors.transparent,
                child: ListView(
                  shrinkWrap: true,
                  children: const [
                    SizedBox(
                      width:
                          double.infinity, // Match the width of the parent Card
                      child: Align(
                        alignment: Alignment
                            .center, // Center the child inside SizedBox
                        child: Padding(
                          padding:
                              EdgeInsets.all(8.0), // Add padding to the text
                          child: Text(
                            'Cart',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(),

                    Card(
                      child: ListTile(
                        title: Text('Product-1'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: Text('Product-2'),
                      ),
                    ),
                    // Add more ListView items as needed
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CartSummary extends StatefulWidget {
  const CartSummary({super.key});

  @override
  State<CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends State<CartSummary> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              width: 350, // Set the desired width for the Card
              child: Card(
                color: Colors.white,
                elevation: 5.0,
                shadowColor: Colors.transparent,
                child: ListView(
                  shrinkWrap: true,
                  children: const [
                    SizedBox(
                      width:
                          double.infinity, // Match the width of the parent Card
                      child: Align(
                        alignment: Alignment
                            .center, // Center the child inside SizedBox
                        child: Padding(
                          padding:
                              EdgeInsets.all(8.0), // Add padding to the text
                          child: Text(
                            'Summary',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(),

                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 15.0, top: 8.0), // Add padding to the text
                          child: Text('Item Cost'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 15.0, top: 8.0), // Add padding to the text
                          child: Text('Delivery Fee'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 15.0, top: 8.0), // Add padding to the text
                          child: Text('GST'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 15.0, top: 8.0), // Add padding to the text
                          child: Text('Total'),
                        ),
                      ],
                    ),
                    // Add more ListView items as needed
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
