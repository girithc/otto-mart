import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  DrawerSections _currentSection = DrawerSections.profile;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
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
              'Pronto',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          onTap: () {
            // Navigate to home screen
            Navigator.pop(
                context); // Assuming home screen is the previous screen
          },
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            // Go back to the previous screen
            Navigator.pop(context);
          },
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
        return const Center(child: Text('Profile Section'));
      case DrawerSections.wallet:
        return const Center(child: Text('Wallet Section'));
      case DrawerSections.orders:
        return const Center(child: Text('Orders Section'));
      case DrawerSections.support:
        return const Center(child: Text('Support Section'));
      // ... handle other sections as required
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
