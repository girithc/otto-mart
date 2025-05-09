import 'package:flutter/material.dart';

class ActiveTabProvider with ChangeNotifier {
  int _activeTabIndex = 0;

  int get activeTabIndex => _activeTabIndex;

  void setActiveTabIndex(int index) {
    print("Active tab index set to: $index"); // Add debug print
    _activeTabIndex = index;
    notifyListeners();
  }
}
