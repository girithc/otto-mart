import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/login/login_status_provider.dart';
import 'package:pronto/login/phone_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurpleAccent,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyHomePage(
                              title: 'Pronto',
                            )));
              },
            ),
            const Text(
              "O",
              style: TextStyle(color: Colors.white, fontSize: 20.0),
            ),
            const Spacer(), // This will push the remaining content to take up the available space
            Align(
              alignment: Alignment.center,
              child: InkWell(
                child: ShaderMask(
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
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const Spacer(), // Another Spacer to push the menu icon to the right
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, size: 30.0, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
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
        return Center(
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
                child: const Text('Log Out')),
          ],
        ));
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
