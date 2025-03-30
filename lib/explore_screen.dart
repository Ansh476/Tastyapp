import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'widgets/recipe_detail_screen.dart';
import 'models/recipe.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Category> categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/categories.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['categories'] != null) {
        setState(() {
          categories = (data['categories'] as List).map((json) => Category.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } else {
      print('Failed to load categories');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Recipe>> fetchCategoryRecipes(String categoryName) async {
    final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?c=$categoryName'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        return (data['meals'] as List).map((json) => Recipe.fromJson(json)).toList();
      } else {
        return [];
      }
    } else {
      print('Failed to load recipes for category: $categoryName');
      return [];
    }
  }

  Future<Recipe?> fetchRecipeDetails(String recipeName) async {
    final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=$recipeName'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && data['meals'].isNotEmpty) {
        return Recipe.fromJson(data['meals'][0]);
      }
    } else {
      print('Failed to load recipe details for $recipeName');
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: EdgeInsets.all(10.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () async {
              List<Recipe> recipes = await fetchCategoryRecipes(category.strCategory);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryRecipeScreen(
                    categoryName: category.strCategory,
                    recipes: recipes,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image.network(
                        category.strCategoryThumb,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Center(child: Icon(Icons.error_outline)),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      category.strCategory,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoryRecipeScreen extends StatelessWidget {
  final String categoryName;
  final List<Recipe> recipes;

  CategoryRecipeScreen({required this.categoryName, required this.recipes});

  Future<Recipe?> fetchRecipeDetails(String recipeName) async {
    final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=$recipeName'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && data['meals'].isNotEmpty) {
        return Recipe.fromJson(data['meals'][0]);
      }
    } else {
      print('Failed to load recipe details for $recipeName');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      backgroundColor: Colors.grey[900],
      body: recipes.isEmpty
          ? Center(
        child: Text(
          'No recipes found for this category.',
          style: TextStyle(color: Colors.white),
        ),
      )
          : ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Card(
            color: Colors.grey[800],
            child: InkWell(
              onTap: () async {
                Recipe? detailedRecipe = await fetchRecipeDetails(recipe.strMeal);
                if (detailedRecipe != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailScreen(recipe: detailedRecipe),
                    ),
                  );
                } else {
                  print('Failed to load detailed recipe');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Image.network(
                      recipe.strMealThumb,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 250,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(Icons.error_outline),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        recipe.strMeal,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Category {
  final String strCategory;
  final String strCategoryThumb;
  final String idCategory;

  Category({
    required this.strCategory,
    required this.strCategoryThumb,
    required this.idCategory,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      strCategory: json['strCategory'],
      strCategoryThumb: json['strCategoryThumb'],
      idCategory: json['idCategory'],
    );
  }
}