import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:provider/provider.dart';
import 'cart/cart.dart';
import 'login/login_status_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isLoggedIn;
  String? customerId; // <-- Add this to store the customerId

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    customerId = await storage.read(key: 'customerId'); // <-- Update this line

    setState(() {
      isLoggedIn = customerId != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoginStatusProvider()),
        ChangeNotifierProxyProvider<LoginStatusProvider, CartModel>(
          create: (context) => CartModel(""),
          update: (context, loginProvider, cartModel) =>
              CartModel(loginProvider.customerId ?? ""),
        ),
      ],
      child: Consumer<LoginStatusProvider>(
        builder: (context, loginProvider, child) {
          return MaterialApp(
            title: 'Provider Demo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: (isLoggedIn == null)
                ? const CircularProgressIndicator() // Loading indicator while checking login status
                : OpeningPageAnimation(isLoggedIn: isLoggedIn!),
          );
        },
      ),
    );
  }
}

class OpeningPageAnimation extends StatefulWidget {
  final bool isLoggedIn;

  const OpeningPageAnimation({required this.isLoggedIn, Key? key})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: _begin, end: _end),
              duration: const Duration(seconds: 4, microseconds: 20),
              builder: (BuildContext context, double position, Widget? child) {
                return Transform.translate(
                  offset: Offset(
                    position * MediaQuery.of(context).size.width,
                    0,
                  ),
                  child: Transform.scale(
                    scale: 0.75,
                    child: child!,
                  ),
                );
              },
              onEnd: () {
                if (widget.isLoggedIn) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const MyHomePage(title: 'Pronto')));
                } else {
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const MyPhone()));
                }
              },
              child: Image.asset('assets/images/scooter.jpg'),
            ),
            const SizedBox(
                height:
                    16), // Provide a bit of spacing between the image and the text
            Animate(
              effects: const [FadeEffect(), ScaleEffect()],
              child: const Text(
                "Grocery Delivery In Minutes.",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
