import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurpleAccent,
        title: ShaderMask(
          shaderCallback: (bounds) => const RadialGradient(
            center: Alignment.topLeft,
            radius: 1.0,
            colors: [Colors.white, Colors.white70],
            tileMode: TileMode.mirror,
          ).createShader(bounds),
          child: const Text(
            'Otto Mart',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        elevation: 4.0,
        surfaceTintColor: Colors.white,
      ),
      body: Form(
        key: formKey,
        child: Container(
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
                  height: 65,
                  child: Pinput(
                    length: 10, // Set the length of the input
                    controller: phoneNumberController,
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    onSubmitted: (pin) {
                      // Handle submission logic here
                    },
                    defaultPinTheme: const PinTheme(
                      width: 40,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                            bottom: BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.deepPurpleAccent,
                              width: 1,
                            ),
                            right: BorderSide(
                              color: Colors.deepPurpleAccent,
                              width: 1,
                            )),
                      ),
                    ),
                    // Add more customization to Pinput as needed
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
                                builder: (context) =>
                                    MyVerify(number: phoneNumber),
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
    );
  }
}
