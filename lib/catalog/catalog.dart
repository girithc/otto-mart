// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';

@immutable
class HigherLevelCategory {
  final int id;
  final String name;

  const HigherLevelCategory({required this.id, required this.name});

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) =>
      other is HigherLevelCategory && (other.id == id && other.name == name);
}
