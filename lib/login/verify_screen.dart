import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:pinput/pinput.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/login/phone_api_client.dart';
import 'package:provider/provider.dart';

class MyVerify extends StatefulWidget {
  const MyVerify({Key? key, required this.number}) : super(key: key);
  final String number; // Mark this as final

  @override
  State<MyVerify> createState() => _MyVerifyState();
}

class _MyVerifyState extends State<MyVerify> {
  late CustomerApiClient apiClient; // Declare apiClient here
  late Customer customer;
  final Logger _logger = Logger();

  final storage = const FlutterSecureStorage();

  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    apiClient = CustomerApiClient(widget.number);
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    final customerId = await storage.read(key: 'customerId');

    setState(() {
      isLoggedIn = customerId != null;
    });
  }

  Future<bool> loginCustomer() async {
    try {
      final loggedCustomer = await apiClient.loginCustomer();
      setState(() {
        customer = loggedCustomer;
        isLoggedIn = true;
        _logger.e("Logged in Customer: ${customer.id}");
      });

      // Store the user's credentials securely
      await storage.write(key: 'customerId', value: customer.id.toString());
      await storage.write(key: 'phone', value: customer.phone.toString());
      await storage.write(key: 'cartId', value: customer.cartId.toString());

      Provider.of<LoginStatusProvider>(context, listen: false)
          .updateLoginStatus(true, customer.id.toString());
      return true; // Login was successful
    } catch (err) {
      _logger.e('(login) customer error $err');
      return false; // Login failed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: ShaderMask(
          shaderCallback: (bounds) => const RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.0,
                  colors: [Colors.white, Colors.white70],
                  tileMode: TileMode.mirror)
              .createShader(bounds),
          child: const Text(
            "Pronto",
            style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.black,
          ),
        ),
        elevation: 4.0,
        surfaceTintColor: Colors.white,
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 25, right: 25),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/img1.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(
                height: 25,
              ),
              const Text(
                "Phone Verification",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 5,
              ),
              const Text(
                "Enter One Time Password",
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 20,
              ),
              Pinput(
                length: 6,
                // defaultPinTheme: defaultPinTheme,
                // focusedPinTheme: focusedPinTheme,
                // submittedPinTheme: submittedPinTheme,

                showCursor: true,
                onCompleted: (pin) => _logger.e(pin),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: () {
                      loginCustomer().then((isSuccess) {
                        if (isSuccess) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MyHomePage(title: "Pronto"),
                            ),
                          );
                        } else {
                          // Show an error message to the user or handle the failure appropriately.
                        }
                      });
                    },
                    child: const Text(
                      "Submit Code",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    )),
              ),
              Row(
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          'phone',
                          (route) => false,
                        );
                      },
                      child: Text(
                        "Edit Phone Number ${widget.number} ? ",
                        style: const TextStyle(color: Colors.deepPurple),
                      ))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
