import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/home/tab/tab.dart';
import 'package:provider/provider.dart';

class MyPlan extends StatefulWidget {
  const MyPlan({super.key});
  static const String routeName = '/MyPlanPage';

  @override
  State<MyPlan> createState() => _MyPlanState();
}

class _MyPlanState extends State<MyPlan> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: () {},
          child: ShaderMask(
            shaderCallback: (bounds) => const RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.0,
                    colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                    tileMode: TileMode.mirror)
                .createShader(bounds),
            child: const Text(
              'Otto Plan',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
      ),
      body: const Center(
        child: Text('Coming Soon'),
      ),
      bottomNavigationBar: Container(
        padding:
            const EdgeInsets.only(bottom: 22, top: 10, left: 15, right: 15),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          color: Colors.white,
        ),
        child: Consumer<ActiveTabProvider>(
          builder: (context, activeTabProvider, child) => GNav(
            gap: 12,
            color: Colors.black87,
            activeColor: Colors.white,
            tabBackgroundColor: Colors.deepPurpleAccent.shade200,
            selectedIndex: activeTabProvider
                .activeTabIndex, // Always set to 0 to keep Home tab active
            onTabChange: (index) {
              // Always navigate to Home, regardless of selected tab
              activeTabProvider.setActiveTabIndex(index);
              if (index == 0) {
                Navigator.pushNamed(context, MyHomePage.routeName);
              } else if (index == 1) {
                Navigator.pushNamed(context, MyPlan.routeName);
              } else if (index == 2) {
                Navigator.pushNamed(context, MyCart.routeName);
              }
            },
            tabs: const [
              GButton(
                icon: Icons.home,
                text: 'Home',
                textStyle:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                padding: EdgeInsets.all(15),
              ),
              GButton(
                icon: Icons.book_outlined,
                text: 'Otto Plan',
                textStyle:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                padding: EdgeInsets.all(15),
              ),
              GButton(
                icon: Icons.shopping_cart_outlined,
                text: 'Otto Cart',
                textStyle:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                padding: EdgeInsets.all(15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
