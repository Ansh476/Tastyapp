import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart'; // Ensure the path is correct
import '../widgets/recipe_detail_screen.dart'; // Ensure correct path


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  List<Recipe> searchResults = [];
  String searchType = 'name'; // Default search type
  TextEditingController searchController = TextEditingController();
  Recipe? randomRecipe; // To store the random recipe
  Timer? _timer;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    fetchRandomRecipe();
    _timer = Timer.periodic(Duration(seconds: 4), (Timer timer) {
      setState(() {
        _opacity = 0.0; // Fade out
      });
      Future.delayed(Duration(milliseconds: 500), () {
        fetchRandomRecipe();
        setState(() {
          _opacity = 1.0; // Fade in
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchRandomRecipe() async {
    final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        setState(() {
          randomRecipe = Recipe.fromJson(data['meals'][0]);
        });
      }
    } else {
      print('Failed to load random recipe');
    }
  }

  Future<void> searchRecipes(String query) async {
    try {
      List<Recipe> results;
      if (searchType == 'name') {
        results = await apiService.searchRecipesByName(query);
      } else {
        results = await apiService.searchRecipesByIngredient(query);
      }
      setState(() {
        searchResults = results;
      });
    } catch (e) {
      print('Error searching recipes: $e');
      // Handle error appropriately (e.g., show a snackbar)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar with Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Recipes...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (query) {
                      searchRecipes(query);
                    },
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: searchType,
                  onChanged: (String? newValue) {
                    setState(() {
                      searchType = newValue!;
                    });
                  },
                  items: <String>['name', 'ingredient']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value == 'name' ? 'Name' : 'Ingredient'),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Random Recipe Display
            AnimatedOpacity(
              opacity: _opacity,
              duration: Duration(milliseconds: 500),
              child: SizedBox(
                height: 300,
                child: InkWell(
                  onTap: randomRecipe != null
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(recipe: randomRecipe!),
                      ),
                    );
                  }
                      : null,
                  child: randomRecipe != null
                      ? Card(
                    elevation: 5,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            randomRecipe!.strMealThumb,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(Icons.error_outline),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            randomRecipe!.strMeal,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Search Results Display
            Expanded(
              child: searchResults.isEmpty
                  ? Center(child: Text('No results found. Start searching!'))
                  : ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  return RecipeCard(recipe: searchResults[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
