import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:pronto/plan/plan.dart';
import 'package:pronto/setting/myaccount.dart';
import 'package:pronto/setting/order/order.dart';
import 'package:pronto/payments/phonepe.dart';
import 'package:provider/provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();

  Future<void> signOutUser(BuildContext context) async {
    // Clear the data in "customerId" key
    if (ModalRoute.of(context)?.isActive == true) {
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
              title: const Text(
                'Confirm',
                style:
                    TextStyle(color: Colors.white), // White text for the title
              ),
              content: const Text(
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
                  child: const Text(
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
                  child: const Text(
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

  void _showNoRewardsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Reduced border radius
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Set the background color to white
              borderRadius: BorderRadius.circular(20), // Reduced border radius
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "0 Rewards Available",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text("Earn rewards to use this feature."),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: InkWell(
          child: ShaderMask(
            shaderCallback: (bounds) => const RadialGradient(
              center: Alignment.topLeft,
              radius: 1.0,
              colors: [Colors.white, Colors.white70],
              tileMode: TileMode.mirror,
            ).createShader(bounds),
            child: const Text(
              'My Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          onTap: () async {
            final storeId = await storage.read(key: 'storeId');
            if (storeId == null || storeId.isEmpty) {
              // If storeId is null or empty, navigate to MyPlan widget
              print("StoreId is  empty: $storeId");
              context.go('/coming-soon');
            } else {
              print("StoreId is not empty: $storeId");
              // If storeId is not null, navigate to MyHomePage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyHomePage(
                    title: 'Otto Mart',
                  ),
                ),
              );
            }
          },
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () async {
            final storeId = await storage.read(key: 'storeId');
            if (storeId == null || storeId.isEmpty) {
              // If storeId is null or empty, navigate to MyPlan widget
              context.go('/coming-soon');
            } else {
              print("StoreId is not empty: $storeId");
              // If storeId is not null, navigate to MyHomePage
              context.go('/home');
            }
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              height: MediaQuery.of(context).size.height * 0.26,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20, top: 10),
                        child: Text(
                          "Wallet \nBalance",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 36,
                              color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 30,
                          top: 10,
                          right: 20,
                        ),
                        child: Text(
                          "\n0",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 36,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showNoRewardsDialog(context);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin:
                              EdgeInsets.only(left: 10, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          height: MediaQuery.of(context).size.height * 0.1,
                          width: MediaQuery.of(context).size.width * 0.25,
                          padding: EdgeInsets.all(10),
                          child: Text(
                            "Redeem Balance",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showNoRewardsDialog(context);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin:
                              EdgeInsets.only(left: 10, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          height: MediaQuery.of(context).size.height * 0.1,
                          width: MediaQuery.of(context).size.width * 0.25,
                          padding: EdgeInsets.all(10),
                          child: Text(
                            "Earn Rewards",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showNoRewardsDialog(context);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(
                              left: 10, top: 10, bottom: 10, right: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          height: MediaQuery.of(context).size.height * 0.1,
                          width: MediaQuery.of(context).size.width * 0.25,
                          padding: EdgeInsets.all(10),
                          child: Text(
                            "Multiply Rewards",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(10), // Apply a borderRadius of 10
                color: Colors
                    .grey.shade100, // Set the background color of the Container
              ),
              child: ListTile(
                minVerticalPadding: 10,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyOrdersPage()),
                  );
                },
                title: const Center(
                  child: Text(
                    'Orders',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_outlined),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(10), // Apply a borderRadius of 10
                color: Colors
                    .grey.shade100, // Set the background color of the Container
              ),
              child: ListTile(
                minVerticalPadding: 10,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyAccountPage()),
                  );
                },
                title: const Center(
                  child: Text(
                    'My Account',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_outlined),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodySection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              // Apply a border only at the top of the Container
              border: Border(
                top: BorderSide(
                    color: Colors.grey.withOpacity(0.4),
                    width:
                        1.0), // Specify the color and width of the top border
              ),
              borderRadius: BorderRadius.circular(
                  2), // Apply the same borderRadius as your ListTile
              color: Colors.white, // Set the background color of the Container
            ),
            child: ListTile(
              minVerticalPadding: 10,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyOrdersPage()),
                );
              },
              title: const Center(
                child: Text(
                  'Orders',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
              // Remove tileColor and shape from ListTile since it's now wrapped in a Container
              trailing: const Icon(Icons.arrow_forward_ios_outlined),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            decoration: BoxDecoration(
              // Apply a border only at the top of the Container
              border: Border(
                top: BorderSide(
                    color: Colors.grey.withOpacity(0.4),
                    width:
                        1.0), // Specify the color and width of the top border
              ),
              borderRadius: BorderRadius.circular(
                  2), // Apply the same borderRadius as your ListTile
              color: Colors.white, // Set the background color of the Container
            ),
            child: ListTile(
              minVerticalPadding: 10,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyAccountPage()),
                );
              },
              title: const Center(
                child: Text(
                  'My Account',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
              // Remove tileColor and shape from ListTile since it's now wrapped in a Container
              trailing: const Icon(Icons.arrow_forward_ios_outlined),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}

enum DrawerSections {
  profile,
  wallet,
  orders,
  support,
  // add more as required
}
