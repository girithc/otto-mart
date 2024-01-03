import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:pronto/setting/order/order.dart';
import 'package:pronto/payments/phonepe.dart';
import 'package:provider/provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  DrawerSections _currentSection = DrawerSections.profile;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> signOutUser(BuildContext context) async {
    // Clear the data in "customerId" key
    if (ModalRoute.of(context)?.isActive == true) {
      //print("Signing Out User");
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'customerId');
      await storage.delete(key: 'cartId');
      await storage.delete(key: 'phone');
    }
    // ignore: use_build_context_synchronously
    Provider.of<LoginStatusProvider>(context, listen: false)
        .updateLoginStatus(false, null);

    // Perform any additional sign-out logic if needed
    // For example, you might want to navigate to the login screen
  }

  // Function to show confirmation dialog
  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor:
                  Colors.deepPurpleAccent, // Set the background color
              title: Text(
                'Confirm',
                style:
                    TextStyle(color: Colors.white), // White text for the title
              ),
              content: Text(
                'Are you sure you want to delete your profile?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18), // White text for the content
              ),
              actions: <Widget>[
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        Colors.white), // White background for buttons
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8), // Squarish roundish border
                      ),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: Colors
                            .deepPurpleAccent), // Deep purple text for buttons
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.white),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.deepPurpleAccent),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Returning false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurpleAccent,
        title: InkWell(
          child: ShaderMask(
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
          onTap: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyHomePage(
                          title: 'Pronto',
                        )));
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      drawer: _buildDrawer(),
      body: _buildBodySection(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: <Widget>[
          const UserAccountsDrawerHeader(
            accountName: Text('John Doe'),
            accountEmail: Text('john.doe@example.com'),
          ),
          ListTile(
            title: const Text('Profile'),
            onTap: () {
              setState(() {
                _currentSection = DrawerSections.profile;
              });
              Navigator.pop(context); // close the drawer
            },
          ),
          ListTile(
            title: const Text('Wallet'),
            onTap: () {
              setState(() {
                _currentSection = DrawerSections.wallet;
              });
              Navigator.pop(context); // close the drawer
            },
          ),
          ListTile(
            title: const Text('Orders'),
            onTap: () {
              setState(() {
                _currentSection = DrawerSections.orders;
              });
              Navigator.pop(context); // close the drawer
            },
          ),
          ListTile(
            title: const Text('Support'),
            onTap: () {
              setState(() {
                _currentSection = DrawerSections.support;
              });
              Navigator.pop(context); // close the drawer
            },
          ),

          // ... add more list tiles as required
        ],
      ),
    );
  }

  Widget _buildBodySection() {
    switch (_currentSection) {
      case DrawerSections.profile:
        return SingleChildScrollView(
          child: Column(
            children: [
              // ... your existing code for order details ...
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyOrdersPage()),
                  );
                },
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.14,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigoAccent.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Orders',
                      style: GoogleFonts.robotoMono(fontSize: 18),
                    ),
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  signOutUser(context).then(
                    (value) => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyPhone()),
                    ),
                  );
                },
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.14,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Sign Out',
                      style: GoogleFonts.robotoMono(
                          fontSize: 18, color: Colors.black),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showConfirmationDialog(context).then((confirmed) {
                    if (confirmed) {
                      signOutUser(context).then(
                        (value) => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyPhone()),
                        ),
                      );
                    }
                  });
                },
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.07,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Delete User',
                      style: GoogleFonts.robotoMono(
                          fontSize: 18, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      /*
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentSection = DrawerSections.orders;
                    });
                  },
                  child: const Text('Orders')),
              ElevatedButton(
                  onPressed: () {
                    signOutUser(context).then(
                      (value) => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyPhone())),
                    );
                  },
                  child: const Text('Log Out'),),
            ],
          ),
        );
        */
      case DrawerSections.wallet:
        return const Center(child: Text('Wallet Section'));
      case DrawerSections.orders:
        return const Center(child: Text('Orders Section'));
      case DrawerSections.support:
        return const Center(child: Text('Support Section'));

      default:
        return const Center(
            child: Text('Please select a section from the drawer.'));
    }
  }
}

enum DrawerSections {
  profile,
  wallet,
  orders,
  support,
  // add more as required
}
