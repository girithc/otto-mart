import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinput/pinput.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/login/phone_api_client.dart';

class MyVerify extends StatefulWidget {
  MyVerify({Key? key, required this.number}) : super(key: key);
  String number;

  @override
  State<MyVerify> createState() => _MyVerifyState();
}

class _MyVerifyState extends State<MyVerify> {
  late CustomerApiClient apiClient; // Declare apiClient here
  late Customer customer;

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

  Future<void> loginCustomer() async {
    try {
      final loggedCustomer = await apiClient.loginCustomer();
      setState(() {
        customer = loggedCustomer;
        isLoggedIn = true;
        print("Logged in Customer: ${customer.id}");
      });

      // Store the user's credentials securely
      await storage.write(key: 'customerId', value: customer.id.toString());
      await storage.write(key: 'phone', value: customer.phone.toString());

      // You can store other user-related data as well
    } catch (err) {
      print('(login) customer error $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 20,
          color: Color.fromRGBO(30, 60, 87, 1),
          fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color.fromRGBO(114, 178, 238, 1)),
      borderRadius: BorderRadius.circular(8),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color.fromRGBO(234, 239, 243, 1),
      ),
    );

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
                onCompleted: (pin) => print(pin),
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
                      loginCustomer().then(
                        (value) => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MyHomePage(
                                      title: "Pronto",
                                    ))),
                      );
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
