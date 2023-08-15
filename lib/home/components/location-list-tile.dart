import 'package:flutter/material.dart';

class LocationListTile extends StatelessWidget {
  const LocationListTile(
      {required this.location, required this.press, super.key});

  final String location;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: press,
          horizontalTitleGap: 0,
          title: Text(
            location,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(
            height: 2, thickness: 2, color: Color.fromARGB(255, 235, 235, 235)),
      ],
    );
  }
}
