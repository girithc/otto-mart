import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:packer/main.dart';
import 'package:packer/utils/constants.dart';
import 'package:packer/utils/constants.dart';
import 'package:pinput/pinput.dart';

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  _PhonePageState createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
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

  Future<String?> loginPacker(String phoneNumber) async {
    try {
      // Send the HTTP request to send OTP
      var url = Uri.parse('$baseUrl/login-packer');
      final Map<String, dynamic> requestData = {"phone": phoneNumber};
      var response = await http.post(
        url,
        body: jsonEncode(requestData),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['phone'];
      } else {
        // Handle HTTP request error
        print(response.body);
        return 'error';
      }
    } catch (error) {
      print('Error(Send OTP): $error');
      return 'error';
    }
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
            'Packer',
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
          margin: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Phone Verification",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "Let's Start Packing!",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 50,
                ),
                SizedBox(
                  height: 80, // Increased height for larger input boxes
                  child: Pinput(
                    separatorBuilder: (index) => Container(
                      height: 64,
                      width: 1,
                      color: Colors.white,
                    ),
                    androidSmsAutofillMethod:
                        AndroidSmsAutofillMethod.smsRetrieverApi,
                    length: 10, // Set the length of the input
                    controller: phoneNumberController,
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    onSubmitted: (pin) {
                      // Handle submission logic here
                    },
                    defaultPinTheme: PinTheme(
                      width: 60,
                      height: 64,
                      textStyle: GoogleFonts.poppins(
                          fontSize: 20, color: Colors.white),
                      decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 36,
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            Colors.white, // Color of the input box when focused
                        border: Border.all(
                          color: Colors
                              .deepPurpleAccent, // Border color when focused
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
                  height: 10,
                ),
                const SizedBox(
                  height: 10,
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
                    onPressed: () async {
                      String phoneNumber = phoneNumberController.text;
                      if (phoneNumber.length == 10) {
                        // Call loginPacker function
                        String? response = await loginPacker(phoneNumber);
                        if (response != 'error') {
                          print("Reponse : $response");
                          const storage = FlutterSecureStorage();
                          await storage.write(
                              key: "packerId", value: phoneNumber);
                          await storage.write(key: "storeId", value: '1');
                          // Success - Navigate to MyHomePage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const MyHomePage(title: 'Otto Master')),
                          );
                        } else {
                          // Handle login failure
                          _showDialog("Login failed. Please try again.");
                        }
                      } else {
                        _showDialog("Phone number must be 10 digits");
                      }
                    },
                    child: const Text(
                      "Login",
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
