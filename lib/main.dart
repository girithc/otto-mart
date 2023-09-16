import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:provider/provider.dart';

import 'cart/cart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    final customerId = await storage.read(key: 'customerId');

    setState(() {
      isLoggedIn = customerId != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using MultiProvider is convenient when providing multiple objects.
    return MultiProvider(
      providers: [
        // In this sample app, CatalogModel never changes, so a simple Provider
        // is sufficient.
        Provider(create: (context) => CartModel()),
        // CartModel is implemented as a ChangeNotifier, which calls for the use
        // of ChangeNotifierProvider. Moreover, CartModel depends
        // on CatalogModel, so a ProxyProvider is needed.

        ChangeNotifierProvider<CartModel>(
          create: (context) => CartModel(),
        ),
      ],
      child: MaterialApp(
          title: 'Provider Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: (isLoggedIn)
              ? const MyHomePage(title: 'Pronto')
              : const MyPhone()),
    );
  }
}
