import 'dart:async';
import 'dart:convert';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/home/address/select/select.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/home/tab/tab.dart';
import 'package:pronto/login/phone_api_client.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:pronto/login/verify_screen.dart';
import 'package:pronto/plan/plan.dart';
import 'package:pronto/setting/setting_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/globals.dart';
import 'package:pronto/utils/no_internet.dart';
import 'package:pronto/utils/no_internet_api.dart';
import 'package:provider/provider.dart';
import 'cart/cart.dart';
import 'login/login_status_provider.dart';

// Define a global key for your navigator

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  String? initialCustomerId = await storage.read(key: 'customerId');

  runApp(MyApp(
    initialCustomerId: initialCustomerId,
  ));
}

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const OpeningPageAnimation();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const MyHomePage(
          title: 'Otto Mart',
        );
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (BuildContext context, GoRouterState state) {
        return const MyCart();
      },
    ),
    GoRoute(
      path: '/phone',
      builder: (BuildContext context, GoRouterState state) {
        return const MyPhone();
      },
    ),
    GoRoute(
      path: '/verify/:number/:istester',
      builder: (BuildContext context, GoRouterState state) {
        final number = state.pathParameters['number'];
        final istester = state.pathParameters['istester'];
        return MyVerify(
          number: number!,
          isTester: bool.parse(istester!),
        );
      },
    ),
    GoRoute(
      path: '/select-address-login',
      builder: (BuildContext context, GoRouterState state) {
        return const AddressSelectionWidget();
      },
    ),
    GoRoute(
      path: '/setting',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingScreen();
      },
    ),
  ],
);

class MyApp extends StatefulWidget {
  final String? initialCustomerId;

  const MyApp({required this.initialCustomerId, Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isLoggedIn;
  late CustomRouteObserver routeObserver;

  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.initialCustomerId != null;
    showAddress = true;
    routeObserver = CustomRouteObserver();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (context) => LoginStatusProvider()),
        ChangeNotifierProvider(create: (context) => ActiveTabProvider()),
        ChangeNotifierProvider(
            create: (context) => AddressModel(widget.initialCustomerId!)),
        ChangeNotifierProxyProvider<LoginStatusProvider, CartModel>(
          create: (context) => CartModel(widget.initialCustomerId ?? ""),
          update: (context, loginProvider, cartModel) =>
              CartModel(loginProvider.customerId ?? ""),
        ),
      ],
      child: Consumer<ConnectivityProvider>(
        builder: (context, connectivityProvider, child) {
          if (!connectivityProvider.hasInternet) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: NoInternetPage(
                onRetry: () {
                  connectivityProvider.checkInternetConnection();
                },
              ),
            );
          }
          return MaterialApp.router(
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
            title: 'Provider Demo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
          );
        },
      ),
    );
  }
}

class OpeningPageAnimation extends StatefulWidget {
  const OpeningPageAnimation({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _OpeningPageAnimationState createState() => _OpeningPageAnimationState();
}

class _OpeningPageAnimationState extends State<OpeningPageAnimation> {
  late double _begin;
  late double _end;
  final storage = const FlutterSecureStorage();
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _begin = -0.5;
    _end = 1;
  }

  Future<bool> checkLoginStatus() async {
    print("Attempt Login On Boot");
    String? phone = await storage.read(key: 'phone');
    print("Attempt Login On Boot : $phone");
    if (phone == null) {
      isLoggedIn == false;
      await storage.deleteAll();
      return false;
    }
    final Map<String, dynamic> requestData = {
      "phone": phone,
    };

    final http.Response response = await http.post(
      Uri.parse('$baseUrl/customer'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestData),
    );
    print("Reponse for login: ${response.statusCode} ${response.body} ");
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final Customer customer = Customer.fromJson(responseBody);
      await storage.write(key: 'customerId', value: customer.id.toString());
      await storage.write(key: 'phone', value: customer.phone.toString());
      await storage.write(key: 'cartId', value: customer.cartId.toString());
      isLoggedIn = true;
      return true;
    } else {
      await storage.deleteAll();
      print('Failed to login Customer');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a default value if null
    print("IsLoggedIn:$isLoggedIn");
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
                checkLoginStatus().then((loggedIn) => {
                      if (loggedIn)
                        {
                          context.go('/select-address-login')
                          /*
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MyHomePage(title: 'Pronto')))
                           */
                        }
                      else
                        {context.go('/phone')}
                    });
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
