import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pronto/login/verify_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:http/http.dart' as http;

class MyPhone extends StatefulWidget {
  const MyPhone({Key? key}) : super(key: key);

  @override
  State<MyPhone> createState() => _MyPhoneState();
}

class _MyPhoneState extends State<MyPhone> {
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController countryController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    countryController.text = "+91";
    super.initState();
  }

  Future<String?> sendOTP(String phoneNumber) async {
    try {
      // Define
      // Send the HTTP request to send OTP
      var url = Uri.parse('$baseUrl/send-otp');
      final Map<String, dynamic> requestData = {
        "phone": int.parse(phoneNumber)
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
      print('Error(Send OTP): $error');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            'Pronto',
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
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 40,
                        child: TextField(
                          controller: countryController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Text(
                        "|",
                        style: TextStyle(fontSize: 33, color: Colors.grey),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: phoneNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Phone",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Phone number is required";
                            } else if (value.length != 10) {
                              return "Phone number must be 10 digits";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
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
                      if (formKey.currentState!.validate()) {
                        // Phone number is valid, extract it and navigate to MyVerify
                        String phoneNumber = phoneNumberController.text;

                        sendOTP(phoneNumber).then((value) => {
                              if (value == "success")
                                {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('OTP sent'),
                                    backgroundColor: Colors.green,
                                  )),
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MyVerify(number: phoneNumber),
                                    ),
                                  )
                                }
                            });
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
