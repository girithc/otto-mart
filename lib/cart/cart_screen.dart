// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:pronto/cart/cart.dart';
import 'package:provider/provider.dart';

class MyCart extends StatelessWidget {
  const MyCart({super.key});

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
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: //Colors.deepPurpleAccent.shade100,
            Theme.of(context).colorScheme.inversePrimary,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _CartList(),
              ),
            ),
            const Divider(height: 4, color: Colors.black),
            _TaxAndDelivery(),
            const Divider(height: 4, color: Colors.black),
            _CartTotal()
          ],
        ),
      ),
    );
  }
}

class _CartList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    var itemNameStyle = Theme.of(context).textTheme.titleMedium;

    if (cart.isEmpty()) {
      return const Center(
          child: Text(
        'Your Cart is Empty',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
      ));
    } else {
      return ListView.builder(
        itemCount: cart.items.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.done),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  final itemId = cart.items[index].productId;
                  context.read<CartModel>().removeItem(itemId: itemId);
                },
              ),
              Text(
                cart.items[index].quantity.toString(),
                style: const TextStyle(fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  cart.addItemToCart(cart.items[index]);
                },
              ),
            ],
          ),
          title: Text(
            cart.items[index].productName,
            style: itemNameStyle,
          ),
        ),
      );
    }
  }
}

class _TaxAndDelivery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tax: ${calculateTax()}', // Replace with your tax calculation logic
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Delivery Fee: ${calculateDeliveryFee()}', // Replace with your delivery fee calculation logic
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  // Add your tax calculation logic here
  double calculateTax() {
    // Replace with your actual tax calculation
    return 10.0;
  }

  // Add your delivery fee calculation logic here
  double calculateDeliveryFee() {
    // Replace with your actual delivery fee calculation
    return 5.0;
  }
}

class _CartTotal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var hugeStyle =
        Theme.of(context).textTheme.displayLarge!.copyWith(fontSize: 48);

    var cart = context.watch<CartModel>();

    return Container(
      color: Colors.white,
      height: 125,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('\$${cart.totalPrice}', style: hugeStyle),
            const SizedBox(width: 24),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Buying not supported yet.')));
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('BUY'),
            ),
          ],
        ),
      ),
    );
  }
}
