import 'package:delivery/firebase/firebase_api.dart';
import 'package:delivery/firebase_options.dart';
import 'package:delivery/home/home_screen.dart';
import 'package:delivery/onboarding/login/service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:delivery/onboarding/login/phone.dart';
import 'package:provider/provider.dart'; // Import your Phone/Login page here

final navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
  await FirebaseApi().initNotifications();
  runApp(ChangeNotifierProvider(
      create: (context) => LoginProvider(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scooter Animation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        // Assuming checkLogin() is an asynchronous method that returns a Future<bool>
        future: Provider.of<LoginProvider>(context, listen: false).checkLogin(),
        builder: (context, snapshot) {
          // Check if the future is complete
          if (snapshot.connectionState == ConnectionState.done) {
            // If the user is logged in
            if (snapshot.data == true) {
              return const MyHomePage();
            } else {
              // If the user is not logged in
              return const MyPhone();
            }
          } else {
            // Show loading indicator while waiting for login check
            return const CircularProgressIndicator();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
