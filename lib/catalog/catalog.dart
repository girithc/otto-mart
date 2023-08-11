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

class SelectedCategoryProvider extends ChangeNotifier {
  int _selectedCategoryID = 0;

  int get selectedCategoryID => _selectedCategoryID;

  void setSelectedCategory(int categoryID) {
    _selectedCategoryID = categoryID;
    notifyListeners();
  }
}

class CatalogProvider extends ChangeNotifier {
  Catalog _catalog = Catalog(categoryID: 0, storeID: 0);

  Catalog get catalog => _catalog;

  void setCatalog(Catalog catalog) {
    _catalog = catalog;

    notifyListeners();
  }
}

class Catalog {
  final int categoryID;
  final int storeID;

  Catalog({required this.categoryID, required this.storeID});
}
