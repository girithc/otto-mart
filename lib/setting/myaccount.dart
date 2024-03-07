import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/login/phone_screen.dart';
import 'package:provider/provider.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                color:
                    Colors.white, // Set the background color of the Container
              ),
              child: ListTile(
                  onTap: () {
                    signOutUser(context).then(
                      (value) => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyPhone()),
                      ),
                    );
                  },
                  title: const Center(
                    child: Text(
                      'Sign Out',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_outlined)),
            ),
            const SizedBox(height: 10),
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
                color:
                    Colors.white, // Set the background color of the Container
              ),
              child: ListTile(
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
                  title: const Center(
                    child: Text(
                      'Delete User',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_outlined)),
            ),
          ],
        ),
      ),
    );
  }
}
