import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/home/address/select/select.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/home/tab/tab.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:pronto/login/verify_screen.dart';
import 'package:pronto/plan/plan.dart';
import 'package:pronto/setting/setting_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/globals.dart';
import 'package:pronto/utils/network/service.dart';
import 'package:pronto/utils/no_internet.dart';
import 'package:pronto/utils/no_internet_api.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'cart/cart.dart';
import 'login/login_status_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Import the intl package

import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const storage = FlutterSecureStorage();
  String? initialCustomerId = await storage.read(key: 'customerId');

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false, // Remove the debug banner

    home: MyApp(
      initialCustomerId: initialCustomerId,
    ),
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
      path: '/coming-soon',
      builder: (BuildContext context, GoRouterState state) {
        return const MyPlan();
      },
    ),
    GoRoute(
      path: '/select-address',
      builder: (BuildContext context, GoRouterState state) {
        return const AddressSelectionWidget(
          flag: false,
        );
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
        return const AddressSelectionWidget(
          flag: true,
        );
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
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    init();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      needToUpdate(context);
    });
    isLoggedIn = widget.initialCustomerId != null;
    showAddress = true;
    routeObserver = CustomRouteObserver();
  }

  init() async {
    String deviceToken = await getDeviceToken();

    await storage.write(key: 'fcm', value: deviceToken);
  }

  Future<void> needToUpdate(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    String platform = Platform.isAndroid
        ? "android"
        : Platform.isIOS
            ? "ios"
            : "";

    print(
        "App Info: $appName, $packageName, $version, $buildNumber, $platform");
    Map<String, dynamic> data = {
      "packageName": packageName,
      "version": version,
      "buildNumber": buildNumber,
      "platform": platform
    };

    var response = await http.post(
      Uri.parse('$baseUrl/need-to-update'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );

    print("Body $data");

    print("Resopnse: ${response.body} ${response.statusCode}  ");
    if (response.statusCode == 200) {
      bool updateRequired = json.decode(response.body)['update_required'];
      bool updateAvailable = json.decode(response.body)['update_available'];
      bool maintenanceRequired =
          json.decode(response.body)['maintenance_required'];
      String endTimeString = json.decode(response.body)['end_time'];

      // Creating a variable to store the end time value as a DateTime object
      DateTime? maintenanceEndTime;

      // Check if endTimeString is not null or empty
      if (endTimeString.isNotEmpty) {
        // Parsing the string to a DateTime object
        maintenanceEndTime = DateTime.parse(endTimeString);
      }

      print("Update Required: $updateRequired");
      if (updateRequired) {
        // ignore: use_build_context_synchronously
        showDialog(
          barrierColor: Colors.deepPurpleAccent
              .withOpacity(0.7), // Whitened-out background

          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () async {
                String appStoreLink = Platform.isAndroid
                    ? 'https://play.google.com/store/apps/details?id=com.otto.pronto'
                    : 'https://apps.apple.com/in/app/otto-mart/id6468983550'; // Use your actual App Store link

                if (await canLaunch(appStoreLink)) {
                  await launch(appStoreLink);
                } else {
                  print('Could not launch $appStoreLink');
                }
              },
              child: Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,

                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20.0)), // Rounded corners
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // To make the dialog wrap its content
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/icon/icon.jpeg',
                        height: MediaQuery.of(context).size.height * 0.2,
                      ),
                    ), // Replace with your image asset
                    Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Update Available',
                        style: TextStyle(
                            fontSize: 24.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Download the new version and get the latest item discounts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.pinkAccent, // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(fontSize: 20),
                        ),
                        onPressed: () async {
                          String appStoreLink = Platform.isAndroid
                              ? 'https://play.google.com/store/apps/details?id=com.otto.pronto'
                              : 'https://apps.apple.com/in/app/otto-mart/id6468983550';

                          if (await canLaunch(appStoreLink)) {
                            await launch(appStoreLink);
                          } else {
                            print('Could not launch $appStoreLink');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (updateAvailable) {
        showDialog(
          barrierColor: Colors.deepPurpleAccent
              .withOpacity(0.7), // Whitened-out background

          context: context,
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () async {
                String appStoreLink = Platform.isAndroid
                    ? 'https://play.google.com/store/apps/details?id=com.otto.pronto'
                    : 'https://apps.apple.com/in/app/otto-mart/id6468983550'; // Use your actual App Store link

                if (await canLaunch(appStoreLink)) {
                  await launch(appStoreLink);
                } else {
                  print('Could not launch $appStoreLink');
                }
              },
              child: Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,

                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20.0)), // Rounded corners
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // To make the dialog wrap its content
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/icon/icon.jpeg',
                        height: MediaQuery.of(context).size.height * 0.2,
                      ),
                    ), // Replace with your image asset
                    Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Update Available',
                        style: TextStyle(
                            fontSize: 24.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Download the new version and get the latest item discounts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.pinkAccent, // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(fontSize: 20),
                        ),
                        onPressed: () async {
                          String appStoreLink = Platform.isAndroid
                              ? 'https://play.google.com/store/apps/details?id=com.otto.pronto'
                              : 'https://apps.apple.com/in/app/otto-mart/id6468983550';

                          if (await canLaunch(appStoreLink)) {
                            await launch(appStoreLink);
                          } else {
                            print('Could not launch $appStoreLink');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (maintenanceRequired) {
        // Format the maintenance end time as a string
        String formattedMaintenanceEndTime = "";
        if (maintenanceEndTime != null) {
          formattedMaintenanceEndTime =
              DateFormat('yyyy-MM-dd – kk:mm').format(maintenanceEndTime);
        }

        showDialog(
          barrierColor: Colors.deepPurpleAccent.withOpacity(0.7),
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () async {},
              child: Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/icon/icon.jpeg',
                        height: MediaQuery.of(context).size.height * 0.2,
                      ),
                    ),
                    Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Under Maintenance',
                        style: TextStyle(
                            fontSize: 24.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(16.0),
                      // Use the formattedMaintenanceEndTime in the message
                      child: Text(
                        'The app is under maintenance until $formattedMaintenanceEndTime.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } else {
      print("Error: ${response.reasonPhrase}");
    }
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
          create: (context) => CartModel(),
          update: (context, loginProvider, cartModel) => CartModel(),
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
            debugShowMaterialGrid: false,
          );
        },
      ),
    );
  }

  //get device token to use for push notification
  Future getDeviceToken() async {
    //request user permission for push notification
    FirebaseMessaging.instance.requestPermission();

    if (Platform.isIOS) {
      var iosToken = await FirebaseMessaging.instance.getAPNSToken();
      print("aps : $iosToken");
    }
    FirebaseMessaging firebaseMessage = FirebaseMessaging.instance;
    String? deviceToken = await firebaseMessage.getToken();
    return (deviceToken == null) ? "" : deviceToken;
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
    _begin = 0.1;
    _end = 0.2;
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

    final networkService = NetworkService();
    final response = await networkService.postWithAuth('/customer',
        additionalData: requestData);

    print("Reponse for login: ${response.statusCode} ${response.body} ");
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final CustomerAutoLogin customer =
          CustomerAutoLogin.fromJson(responseBody);

      await storage.write(key: 'customerId', value: customer.id.toString());
      await storage.write(key: 'phone', value: customer.phone);
      await storage.write(key: 'name', value: customer.name);
      await storage.write(key: 'authToken', value: customer.token);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: _begin, end: _end),
              duration: const Duration(microseconds: 1),
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
                          print("Logged IN"),
                          context.go('/select-address-login')
                        }
                      else
                        {context.go('/phone')}
                    });
              },
              child: SizedBox.shrink(),
            ),
            const SizedBox(
                height:
                    16), // Provide a bit of spacing between the image and the text
            Animate(
              effects: const [FadeEffect(), ScaleEffect()],
              child: const Text(
                "",
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
