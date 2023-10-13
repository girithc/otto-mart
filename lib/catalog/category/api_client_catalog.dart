import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pronto/utils/constants.dart';

class CatalogApiClient {
  final String localBaseUrl;

  CatalogApiClient(this.localBaseUrl);

  Future<List<Category>> fetchCategories(int id) async {
    var url = Uri.parse('$baseUrl/category');

    if (id == 0) {
      throw Exception('(CatalogApiClient) Parameters are not valid');
    }

    var queryParams = {'id': id.toString()};
    url = url.replace(queryParameters: queryParams);

    http.Response response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Category> categories =
          jsonData.map((item) => Category.fromJson(item)).toList();
      return categories;
    } else {
      throw Exception('Failed to load categories');
    }
  }
}

class Category {
  final int id;
  final String name;
  final String image;

  Category({required this.id, required this.name, required this.image});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'], name: json['name'], image: json['image']);
  }
}
