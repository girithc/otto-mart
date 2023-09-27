import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        Provider(
            create: (context) =>
                CartModel(customerId ?? "")), // <-- Update this line
        ChangeNotifierProvider<CartModel>(
          create: (context) =>
              CartModel(customerId ?? ""), // <-- Update this line
        ),
      ],
      child: MaterialApp(
        title: 'Provider Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: (isLoggedIn == null)
            ? const CircularProgressIndicator() // Loading indicator while checking login status
            : OpeningPageAnimation(isLoggedIn: isLoggedIn!),
      ),
    );
  }
}

class OpeningPageAnimation extends StatefulWidget {
  final bool isLoggedIn;

  const OpeningPageAnimation({required this.isLoggedIn, Key? key})
      : super(key: key);

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
              child: Image.asset('assets/images/scooter.avif'),
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
