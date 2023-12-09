import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:pinput/pinput.dart';
import 'package:pronto/home/address/select/select.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/login/phone_api_client.dart';
import 'package:pronto/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MyVerify extends StatefulWidget {
  const MyVerify({Key? key, required this.number, required this.isTester})
      : super(key: key);
  final String number; // Mark this as final
  final bool isTester;
  @override
  State<MyVerify> createState() => _MyVerifyState();
}

class _MyVerifyState extends State<MyVerify> {
  late CustomerApiClient apiClient; // Declare apiClient here
  late Customer customer;
  final Logger _logger = Logger();
  final storage = const FlutterSecureStorage();
  bool isLoggedIn = false;

  final pinController = TextEditingController();
  final focusNode = FocusNode();
  final formKey = GlobalKey<FormState>();
  bool isPinCorrect = false; // State variable to track pin correctness

  @override
  void initState() {
    super.initState();
    apiClient = CustomerApiClient(widget.number);
    checkLoginStatus();
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
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

  Future<String?> verifyOTP(String phoneNumber, String otp) async {
    try {
      // Define
      // Send the HTTP request to send OTP
      var url = Uri.parse('$baseUrl/verify-otp');
      final Map<String, dynamic> requestData = {
        "phone": int.parse(phoneNumber),
        "otp": int.parse(otp)
      };
      var response = await http.post(
        url,
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        // Successfully sent OTP, parse the response
        Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Check the 'type' field in the response
        return jsonResponse['type'];
      } else {
        // Handle HTTP request error
        return response.reasonPhrase;
      }
    } catch (error) {
      // Handle other errors
      print('Error(Verify OTP): $error');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const focusedBorderColor = Colors.deepPurpleAccent;
    const fillColor = Color.fromRGBO(243, 246, 249, 0);
    const borderColor = Colors.greenAccent;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
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
                onChanged: (value) {
                  bool correct = value == '1234';
                  if (isPinCorrect != correct) {
                    setState(() {
                      isPinCorrect = correct;
                    });
                  }
                },
                controller: pinController,
                focusNode: focusNode,
                keyboardType: TextInputType.number, // Restrict to number input
                androidSmsAutofillMethod:
                    AndroidSmsAutofillMethod.smsUserConsentApi,
                listenForMultipleSmsOnAndroid: true,
                defaultPinTheme: defaultPinTheme,
                separatorBuilder: (index) => const SizedBox(width: 8),
                validator: (value) {
                  if (value?.length == 4) {
                    setState(() {
                      isPinCorrect = true; // Set flag to true if pin is correct
                    });
                    return null;
                  } else {
                    setState(() {
                      isPinCorrect =
                          false; // Set flag to false if pin is incorrect
                    });
                    return null; // Validation message
                  }
                },
                // onClipboardFound: (value) {
                //   debugPrint('onClipboardFound: $value');
                //   pinController.setText(value);
                // },
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                onCompleted: (pin) {
                  debugPrint('onCompleted: $pin');
                },
                cursor: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      width: 22,
                      height: 1,
                      color: focusedBorderColor,
                    ),
                  ],
                ),
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: focusedBorderColor),
                  ),
                ),
                submittedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    color: isPinCorrect
                        ? Colors.lightGreenAccent
                        : fillColor, // Change color based on pin correctness
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: focusedBorderColor),
                  ),
                ),
                errorPinTheme: defaultPinTheme.copyBorderWith(
                  border: Border.all(color: Colors.redAccent),
                ),
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
                      widget.isTester
                          ? loginCustomer().then((isSuccess) {
                              if (isSuccess) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddressSelectionWidget(),
                                  ),
                                );
                              } else {
                                // Show an error message to the user or handle the failure appropriately.
                              }
                            })
                          : null;

                      String otp = pinController.text;
                      isPinCorrect
                          ? verifyOTP(widget.number, otp).then((value) {
                              if (value == 'success') {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text('OTP verified'),
                                  backgroundColor: Colors.green,
                                ));
                                loginCustomer().then((isSuccess) {
                                  if (isSuccess) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddressSelectionWidget(),
                                      ),
                                    );
                                  } else {
                                    // Show an error message to the user or handle the failure appropriately.
                                  }
                                });
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text('OTP Invalid'),
                                  backgroundColor: Colors.deepOrangeAccent,
                                ));
                              }
                            })
                          : null; // Button is disabled if isPinCorrect is false
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
