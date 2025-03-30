import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class ApiService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<Recipe>> searchRecipesByName(String name) async {
    final response = await http.get(Uri.parse('$baseUrl/search.php?s=$name'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['meals'] != null) {
        return List<Recipe>.from(json['meals'].map((meal) => Recipe.fromJson(meal)));
      } else {
        return []; // Return empty list when there are no search results
      }
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<List<Recipe>> searchRecipesByIngredient(String ingredient) async {
    final response = await http.get(Uri.parse('$baseUrl/filter.php?i=$ingredient'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['meals'] != null) {
        // The filter API returns a simplified list of meals, so we need to fetch the details for each
        List<Future<Recipe>> recipeFutures = (json['meals'] as List).map((meal) async {
          final id = meal['idMeal'];
          final response = await http.get(Uri.parse('$baseUrl/lookup.php?i=$id'));
          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            if (json['meals'] != null) {
              return Recipe.fromJson(json['meals'][0]);
            } else {
              throw Exception('Failed to load recipe details for id: $id');
            }
          } else {
            throw Exception('Failed to load recipe details for id: $id');
          }
        }).toList();

        return Future.wait(recipeFutures); // Wait for all futures to complete
      } else {
        return []; // Return empty list when there are no search results
      }
    } else {
      throw Exception('Failed to load recipes');
    }
  }
}