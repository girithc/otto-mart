import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:pronto/login/legal/privacy.dart';
import 'package:pronto/login/legal/terms.dart';
import 'package:pronto/login/skip/skip_home.dart';
import 'package:pronto/login/verify_screen.dart';
import 'package:pronto/utils/constants.dart';
import 'package:pronto/utils/network/service.dart';
import 'package:upgrader/upgrader.dart';

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

  final ScrollController _scrollController1 = ScrollController();
  final ScrollController _scrollController2 = ScrollController();

  final List<String> imageUrls = [
    "https://images.thedermaco.com/TheDermaCoLogo2-min.png",
    "https://pbs.twimg.com/profile_images/960482674786930689/Gh_H-EuI_400x400.jpg",
    "https://logos-world.net/wp-content/uploads/2020/11/Gillette-Venus-Logo.png",
    "https://1000marcas.net/wp-content/uploads/2021/05/Neutrogena-Logo-1-1280x720.png",
    "https://pbs.twimg.com/profile_images/1709116198502203392/mi6K51uL_400x400.jpg",
    "https://i.pinimg.com/originals/31/38/a3/3138a3973a60be980ae2acc3bec77aa1.png",
    "https://i.pinimg.com/736x/1c/06/9e/1c069efccc16644dc14f27720ec4c41f.jpg",
    "https://images.squarespace-cdn.com/content/v1/62258e3935ba58479234169a/ac4062d5-43e0-4366-887f-09d24324b638/cinthol.png",
    "https://upload.wikimedia.org/wikipedia/en/a/a9/Dettol_logo.png",
    "https://www.headandshoulders.co.uk/images/page-logo.png",
    "https://images.squarespace-cdn.com/content/v1/570b9bd42fe131a6e20717c2/1632479652642-TJEIEKVTP3YVTTEO4LH9/park-avenue_packagingstructure_elephantdesign_india_singapore-banner-06.jpg",
    "https://1000logos.net/wp-content/uploads/2020/03/Durex-Logo-2020.png",
    "https://i.pinimg.com/originals/b8/70/7b/b8707b6e4d8bcf82c3d0cd864eb8d2b6.jpg"
  ];

  @override
  void initState() {
    countryController.text = "+91";
    super.initState();
    phoneNumberController.addListener(() {
      String text = phoneNumberController.text;
      if (text.length == 10) {
        // Call your method to handle form submission here
        _submitForm();
      }
    });

    _autoScroll(_scrollController1, AxisDirection.right);
    _autoScroll(_scrollController2, AxisDirection.left);
  }

  void _autoScroll(ScrollController controller, AxisDirection direction) {
    Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (controller.hasClients) {
        double maxScrollExtent = controller.position.maxScrollExtent;
        double offset = controller.offset;

        if (direction == AxisDirection.right) {
          if (offset >= maxScrollExtent) {
            controller.jumpTo(0); // Reset to start
          } else {
            controller.jumpTo(offset + 1);
          }
        } else {
          if (offset <= 0) {
            controller.jumpTo(maxScrollExtent); // Reset to end
          } else {
            controller.jumpTo(offset - 1);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    // Don't forget to dispose the controller when the widget is removed
    phoneNumberController.dispose();
    _scrollController1.dispose();
    _scrollController2.dispose();
    super.dispose();
  }

  void _submitForm() {
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
          print("TEST");
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
      final networkService = NetworkService();
      // Send the HTTP request to send OTP
      var url = Uri.parse('$baseUrl/send-otp');
      final Map<String, dynamic> requestData = {"phone": phoneNumber};

      /*
      var response = await http.post(
        url,
        body: jsonEncode(requestData),
        headers: {"Content-Type": "application/json"},
      );
      */

      final response = await networkService.postWithAuth('/send-otp',
          additionalData: requestData);

      print(response.statusCode);
      print(response.body);
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Form(
                  key: formKey,
                  child: Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05,
                        ),
                        Container(
                          // Increased height for a larger input area
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10),

                          child: Column(
                            children: [
                              Text(
                                "Personal Care\nDelivered\nPan India",
                                style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.15,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imageUrls.length,
                            controller: _scrollController1,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.all(8.0),
                                width:
                                    MediaQuery.of(context).size.height * 0.15,
                                height:
                                    MediaQuery.of(context).size.height * 0.08,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 1,
                                      offset: const Offset(
                                          0, 1), // changes position of shadow
                                    ),
                                  ],
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  color: Colors.white,
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrls[index]),
                                    fit: BoxFit.contain,
                                  ),
                                  shape: BoxShape.rectangle,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01,
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.15,
                          margin: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).size.height * 0.05),
                          child: ListView.builder(
                            controller: _scrollController2,
                            scrollDirection: Axis.horizontal,
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.all(8.0),
                                width:
                                    MediaQuery.of(context).size.height * 0.15,
                                height:
                                    MediaQuery.of(context).size.height * 0.08,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 1,
                                      offset: const Offset(
                                          0, 1), // changes position of shadow
                                    ),
                                  ],
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  color: Colors.white,
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrls[index]),
                                    fit: BoxFit.contain,
                                  ),
                                  shape: BoxShape.rectangle,
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          height:
                              48, // Increased height for a larger input area
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(
                                    0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 2,
                              ),
                              const SizedBox(
                                width: 50,
                                child: Text(
                                  "+91",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black),
                                ),
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  keyboardType: TextInputType.phone,
                                  controller: phoneNumberController,
                                  decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Enter phone number',
                                      hintStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      counterText: ""),
                                  maxLength: 10, // Limit the input to 10 digits
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 11, 128),
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
                                    print("TEST");
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
                              "Continue",
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
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Terms()),
                            );
                          },
                          child: const Text(
                            'Terms',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Privacy()),
                            );
                          },
                          child: const Text(
                            'Privacy',
                            style: TextStyle(color: Colors.black),
                          ),
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
                            'Guest',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        /*
        bottomNavigationBar: BottomAppBar(
          color: Colors.amberAccent,
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
                    child: const Text('Terms'),
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
        */
      ),
    );
  }
}
