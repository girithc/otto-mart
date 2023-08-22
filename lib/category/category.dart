import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryApiClient {
  final String baseUrl;

  CategoryApiClient(this.baseUrl);

  Future<List<Category>> fetchCategories() async {
    var url = Uri.parse('http://localhost:3000/category');

    //var queryParams = {'id': id.toString()};
    //url = url.replace(queryParameters: queryParams);

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

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}
