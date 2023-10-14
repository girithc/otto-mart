import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pronto/utils/constants.dart';

class HomeApiClient {
  final String localbaseUrl;

  HomeApiClient(this.localbaseUrl);

  Future<List<Category>> fetchCategories() async {
    var request =
        http.Request('GET', Uri.parse('$baseUrl/higher-level-category'));

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

  Future<List<Category>> fetchPromotions() async {
    var url = Uri.parse('$baseUrl/category');

    var queryParams = {'promotion': "true"};
    url = url.replace(queryParameters: queryParams);

    http.Response response = await http.get(url);
    //print("Response200 ${response.body}");

    if (response.statusCode == 200) {
      print("Response200 ${response.body}");
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
