import 'package:flutter/foundation.dart';

class SearchData extends ChangeNotifier {
  String _searchQuery = "";
  List<String> _searchResults = [];

  String get searchQuery => _searchQuery;
  List<String> get searchResults => _searchResults;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateSearchResults(List<String> results) {
    _searchResults = results;
    notifyListeners();
  }
}
