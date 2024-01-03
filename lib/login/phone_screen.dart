import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:pronto/login/legal/privacy.dart';
import 'package:pronto/login/legal/terms.dart';
import 'package:pronto/login/skip/skip_home.dart';
import 'package:pronto/login/verify_screen.dart';
import 'package:pronto/utils/constants.dart';

// Main widget for phone number verification
class MyPhone extends StatefulWidget {
  const MyPhone({super.key});

  @override
  _MyPhoneState createState() => _MyPhoneState();
}

class _MyPhoneState extends State<MyPhone> {
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  bool isTesterVersion = false; // To track the state of the checkbox

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    countryController.text = "+91";
    super.initState();
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Message"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> sendOTP(String phoneNumber) async {
    try {
      // Send the HTTP request to send OTP
      var url = Uri.parse('$baseUrl/send-otp');
      final Map<String, dynamic> requestData = {
        "phone": int.parse(phoneNumber)
      };
      var response = await http.post(
        url,
        body: jsonEncode(requestData),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['type'];
      } else {
        // Handle HTTP request error
        return response.reasonPhrase;
      }
    } catch (error) {
      print('Error(Send OTP): $error');
      return null;
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Form(
        key: formKey,
        child: Container(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 15),
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
                  height: 10,
                ),
                const Text(
                  "Let's Start Saving!",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 30,
                ),
                SizedBox(
                  height: 80, // Increased height for larger input boxes
                  child: Pinput(
                    length: 10, // Set the length of the input
                    controller: phoneNumberController,
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    onSubmitted: (pin) {
                      // Handle submission logic here
                    },
                    defaultPinTheme: PinTheme(
                      width: 60, // Increased width for larger input boxes
                      height: 60, // Increased height for larger input boxes
                      decoration: BoxDecoration(
                        color: Colors.white, // Uniform color for each input box
                        border: Border.all(
                          color: Colors.deepPurpleAccent, // Border color
                          width: 2, // Border width
                        ),
                        borderRadius:
                            BorderRadius.circular(10), // More rounded borders
                      ),
                      textStyle: const TextStyle(
                        fontSize: 26, // Larger font size for better visibility
                        color: Colors.black, // Text color
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            Colors.white, // Color of the input box when focused
                        border: Border.all(
                          color:
                              Colors.greenAccent, // Border color when focused
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 28,
                        color: Colors.black, // Text color when focused
                      ),
                    ),
                    // Add more customization to Pinput as needed
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      String phoneNumber = phoneNumberController.text;
                      if (phoneNumber.length == 10) {
                        sendOTP(phoneNumber).then((value) {
                          if (value == "success") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyVerify(
                                  number: phoneNumber,
                                  isTester: false,
                                ),
                              ),
                            );
                          } else if (value == "test") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyVerify(
                                  number: '1234567890',
                                  isTester: true,
                                ),
                              ),
                            );
                          } else {
                            _showDialog(value ?? 'Failed to send OTP');
                          }
                        });
                      } else {
                        _showDialog("Phone number must be 10 digits");
                      }
                    },
                    child: const Text(
                      "Send OTP code",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.0,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Terms()),
                    );
                  },
                  child: const Text('Terms Of Use'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Privacy()),
                    );
                  },
                  child: const Text('Privacy'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SkipHomePage(
                                title: 'Otto Mart',
                              )),
                    );
                  },
                  child: const Text(
                    'Guest User',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
