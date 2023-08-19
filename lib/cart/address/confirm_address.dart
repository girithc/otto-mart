import 'package:flutter/material.dart';
import 'package:pronto/home/models/prediction_auto_complete.dart';

class ConfirmAddress extends StatelessWidget {
  final String placeId;
  final StructuredFormatting structuredFormatting;
  const ConfirmAddress(
      {required this.placeId, required this.structuredFormatting, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Confirm Address'),
        ),
        body: Center(
          child: Column(
            children: [
              Text(placeId),
              Text(structuredFormatting.mainText!),
              Text(structuredFormatting.secondaryText!)
            ],
          ),
        ));
  }
}
