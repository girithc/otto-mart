import 'package:flutter/material.dart';
import 'package:master/category/category.dart';
import 'package:master/item/items.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  final CategoryApiClient apiClient =
      CategoryApiClient('https://localhost:3000');
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await apiClient.fetchCategories();
      setState(() {
        categories = fetchedCategories;
        print(categories[1].name);
      });
    } catch (err) {
      print('(catalog)fetchCategories error $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(categories[index].name),
          onTap: () => {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Items(
                  categoryId: categories[index].id,
                  categoryName: categories[index].name,
                ),
              ),
            )
          },
        );
      },
    );
  }
}
