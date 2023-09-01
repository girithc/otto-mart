import 'package:flutter/material.dart';
import 'package:master/store/stores.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pronto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Pronto'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 4.0,
          shadowColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            widget.title,
            style: const TextStyle(
                color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
          ),
        ),
        body: const InventoryManagement()
        //const Stores(), // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}

class InventoryManagement extends StatelessWidget {
  const InventoryManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.store_outlined),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_outlined),
          title: const Text('Stores'),
          onTap: () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Stores()),
            )
          },
          shape: ContinuousRectangleBorder(
            side: const BorderSide(width: 4, color: Colors.white),
            borderRadius: BorderRadius.circular(20),
          ),
          tileColor: const Color.fromARGB(255, 248, 219, 253),
          contentPadding: const EdgeInsets.all(10),
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.white, //Color.fromARGB(255, 248, 219, 253),
            child: Icon(Icons.shopping_bag_outlined),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_outlined),
          title: const Text(
            'Items',
          ),
          onTap: () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Stores()),
            )
          },
          shape: ContinuousRectangleBorder(
            side: const BorderSide(width: 4, color: Colors.white),
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(10),
          tileColor: const Color.fromARGB(255, 248, 219, 253),
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.white, //Colors.white,
            child: Icon(Icons.analytics_outlined),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_outlined),
          title: const Text('Analytics'),
          onTap: () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Stores()),
            )
          },
          shape: ContinuousRectangleBorder(
            side: const BorderSide(width: 4, color: Colors.white),
            borderRadius: BorderRadius.circular(20),
          ),
          tileColor: const Color.fromARGB(255, 248, 219, 253),
          contentPadding: const EdgeInsets.all(10),
        ),
      ],
    );
  }
}
