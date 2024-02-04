import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:pinput/pinput.dart';
import 'package:pronto/home/address/select/select.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/login/phone_api_client.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/network/service.dart';
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
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  final formKey = GlobalKey<FormState>();

  bool isPinCorrect = false; // State variable to track pin correctness
  bool isLoggedIn = false;

  Timer? _timer;
  int _start = 60; // Countdown time in seconds

  @override
  void initState() {
    super.initState();
    apiClient = CustomerApiClient(widget.number);
    checkLoginStatus();
    startTimer();
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    _timer?.cancel();

    super.dispose();
  }

  Future<void> checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    final customerId = await storage.read(key: 'customerId');

    setState(() {
      isLoggedIn = customerId != null;
    });
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  void resendOTP() {
    // Implement the logic to resend OTP
    // After sending the OTP, restart the timer
    setState(() {
      _start = 60; // Reset timer to 60 seconds
    });
    startTimer();
    // Show a message to the user that OTP has been resent
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP has been resent.'),
      ),
    );
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

      Provider.of<LoginStatusProvider>(context, listen: false)
          .updateLoginStatus(true, customer.id.toString());
      return true; // Login was successful
    } catch (err) {
      _logger.e('(login) customer error $err');
      return false; // Login failed
    }
  }

  Future<CustomerLoginResponse?> verifyOTP(
      String phoneNumber, String otp) async {
    try {
      //var url = Uri.parse('$baseUrl/verify-otp');
      final fcm = await storage.read(key: 'fcm');
      final Map<String, dynamic> requestData = {
        "phone": phoneNumber,
        "otp": int.parse(otp),
        "fcm": fcm
      };

      final networkService = NetworkService();
      final response = await networkService.postWithAuth('/verify-otp',
          additionalData: requestData);

      if (response.statusCode == 200) {
        print(response.statusCode);
        print(response.body);
        // Successfully verified OTP, parse the response
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        final customerLoginResponse =
            CustomerLoginResponse.fromJson(jsonResponse);
        await storage.write(
            key: 'authToken', value: customerLoginResponse.customer?.token);
        await storage.write(
            key: 'customerId', value: customerLoginResponse.customer?.phone);
        return customerLoginResponse;
      } else {
        // Handle HTTP request error by creating a response with the error message
        return CustomerLoginResponse(
          message: response.reasonPhrase ?? "Unknown error",
          type: "error",
        );
      }
    } catch (error) {
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
      body: Container(
        margin: const EdgeInsets.only(left: 25, right: 25),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon/icon.jpeg',
                height: 250,
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
              AutofillGroup(
                child: Pinput(
                  onChanged: (value) {
                    if (value.length == 4) {
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
                              if (value!.type == 'success') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddressSelectionWidget(),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text('OTP Invalid'),
                                  backgroundColor: Colors.deepOrangeAccent,
                                ));
                              }
                            })
                          : null;
                    }
                  },
                  controller: pinController,
                  focusNode: focusNode,
                  keyboardType:
                      TextInputType.number, // Restrict to number input
                  androidSmsAutofillMethod:
                      AndroidSmsAutofillMethod.smsUserConsentApi,
                  autofillHints: const [
                    AutofillHints.oneTimeCode
                  ], // Suggest iOS this is for OTP
                  defaultPinTheme: defaultPinTheme,
                  separatorBuilder: (index) => const SizedBox(width: 8),
                  validator: (value) {
                    if (value?.length == 4) {
                      setState(() {
                        isPinCorrect =
                            true; // Set flag to true if pin is correct
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
                            if (value!.type == 'success') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddressSelectionWidget(),
                                ),
                              );
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
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                height: 55,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
                              if (value!.type == 'success') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddressSelectionWidget(),
                                  ),
                                );
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
              Container(
                margin: const EdgeInsets.only(top: 20, left: 12),
                alignment: Alignment.centerLeft,
                child: (_start > 0)
                    ? Text(
                        "Resend OTP: $_start seconds",
                        style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold),
                      )
                    : TextButton(
                        onPressed: () => resendOTP(),
                        child: const Text(
                          "Resend OTP",
                          style: TextStyle(color: Colors.deepPurple),
                        ),
                      ),
              ),
              Row(
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyPhone(),
                          ),
                        );
                      },
                      child: Text(
                        "Edit Phone Number ${widget.number} ? ",
                        style: const TextStyle(
                          color: Colors.deepPurple,
                        ),
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

class CustomerLoginResponse {
  final String message;
  final String type;
  CustomerLogin? customer;

  CustomerLoginResponse({
    required this.message,
    required this.type,
    this.customer,
  });

  factory CustomerLoginResponse.fromJson(Map<String, dynamic> json) {
    return CustomerLoginResponse(
      message: json['message'],
      type: json['type'],
      customer: CustomerLogin.fromJson(json['Customer']),
    );
  }
}

class CustomerLogin {
  final int id;
  final String name;
  final String phone;
  final String address;
  final String merchantUserID;
  final DateTime createdAt;
  final String
      token; // Adjusted for Dart, as it doesn't have a built-in UUID type

  CustomerLogin({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.merchantUserID,
    required this.createdAt,
    required this.token,
  });

  factory CustomerLogin.fromJson(Map<String, dynamic> json) {
    return CustomerLogin(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      merchantUserID: json['merchant_user_id'],
      createdAt: DateTime.parse(json['created_at']),
      token: json['token'],
    );
  }
}
