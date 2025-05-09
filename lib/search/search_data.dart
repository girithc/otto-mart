import 'package:flutter/foundation.dart';
import 'package:pronto/search/search_item.dart';

class SearchData extends ChangeNotifier {
  String _searchQuery = "";
  List<Item> _searchResults = [];
  bool _notFound = false;

  String get searchQuery => _searchQuery;
  List<Item> get searchResults => _searchResults;
  bool get notFound => _notFound;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateSearchResults(List<Item> results) {
    _searchResults = results;
    _notFound = false;
    notifyListeners();
  }

  void updateNotFound() {
    _notFound = true;
    notifyListeners();
  }
}
