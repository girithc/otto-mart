import 'dart:convert';
import 'package:http/http.dart' as http;

class CatalogApiClient {
  final String baseUrl;

  CatalogApiClient(this.baseUrl);

  Future<List<Category>> fetchCategories() async {
    var request =
        http.Request('GET', Uri.parse('http://localhost:3000/category'));

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final String responseBody = await response.stream.bytesToString();
      final List<dynamic> jsonData = json.decode(responseBody);
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

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}
