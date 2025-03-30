import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../widgets/recipe_detail_screen.dart';

class LikedRecipesScreen extends StatefulWidget {
  @override
  _LikedRecipesScreenState createState() => _LikedRecipesScreenState();
}

class _LikedRecipesScreenState extends State<LikedRecipesScreen> {
  List<Recipe> likedRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLikedRecipes();
  }

  Future<void> fetchLikedRecipes() async {
    setState(() {
      _isLoading = true;
    });
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (snapshot.exists) {
      final userData = snapshot.data() as Map<String, dynamic>;
      List<dynamic> likedRecipeIds = userData['likedRecipes'] ?? [];

      List<Recipe> fetchedRecipes = [];
      for (String recipeId in likedRecipeIds) {
        // Fetch detailed recipe information using the recipeId
        Recipe? detailedRecipe = await fetchRecipeDetails(recipeId);
        if (detailedRecipe != null) {
          fetchedRecipes.add(detailedRecipe);
        }
      }

      setState(() {
        likedRecipes = fetchedRecipes;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Recipe?> fetchRecipeDetails(String recipeId) async {
    try {
      final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/lookup.php?i=$recipeId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return Recipe.fromJson(data['meals'][0]);
        }
      }
    } catch (e) {
      print('Error fetching recipe details: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Liked Recipes')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : likedRecipes.isEmpty
          ? Center(child: Text("No liked recipes found", style: TextStyle(color: Colors.white)))
          : ListView.builder(
        itemCount: likedRecipes.length,
        itemBuilder: (context, index) {
          final recipe = likedRecipes[index];
          return buildRecipeCard(context, recipe);
        },
      ),
    );
  }

  Widget buildRecipeCard(BuildContext context, Recipe recipe) {
    return Card(
      color: Colors.grey[800],
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
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
              Text(
                recipe.strMeal,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}