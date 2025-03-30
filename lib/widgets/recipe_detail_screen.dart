import 'package:flutter/material.dart';
import 'package:flutter_mpllab/models/recipe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  RecipeDetailScreen({required this.recipe});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isLiked = false;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    checkIfLiked();
    checkIfSaved();
  }

  Future<void> checkIfLiked() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (snapshot.exists) {
      final userData = snapshot.data() as Map<String, dynamic>;
      List<dynamic> likedRecipeIds = userData['likedRecipes'] ?? [];

      setState(() {
        isLiked = likedRecipeIds.contains(widget.recipe.idMeal);
      });
    }
  }

  Future<void> checkIfSaved() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (snapshot.exists) {
      final userData = snapshot.data() as Map<String, dynamic>;
      List<dynamic> savedRecipeIds = userData['savedRecipes'] ?? [];

      setState(() {
        isSaved = savedRecipeIds.contains(widget.recipe.idMeal);
      });
    }
  }

  Future<void> toggleLike() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    if (isLiked) {
      await userRef.update({
        'likedRecipes': FieldValue.arrayRemove([widget.recipe.idMeal])
      });
    } else {
      await userRef.update({
        'likedRecipes': FieldValue.arrayUnion([widget.recipe.idMeal])
      });
    }

    setState(() {
      isLiked = !isLiked;
    });
  }

  Future<void> toggleSave() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    if (isSaved) {
      await userRef.update({
        'savedRecipes': FieldValue.arrayRemove([widget.recipe.idMeal])
      });
    } else {
      await userRef.update({
        'savedRecipes': FieldValue.arrayUnion([widget.recipe.idMeal])
      });
    }

    setState(() {
      isSaved = !isSaved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasty'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( // Use Expanded to allow the title to take available space
                  child: Text(
                    widget.recipe.strMeal,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                    maxLines: 2, // Allow up to 2 lines
                  ),
                ),
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                  color: isLiked ? Colors.red : null,
                  onPressed: toggleLike,
                ),
              ],
            ),
            SizedBox(height: 10),
            Image.network(
              widget.recipe.strMealThumb,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(Icons.error_outline),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              'Ingredients:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.recipe.ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = widget.recipe.ingredients[index];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ingredient.name,
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            ingredient.measure,
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.grey[700], // Dull grey line
                      height: 1,
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              'Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              widget.recipe.strInstructions,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute space evenly
              children: [
                if (widget.recipe.strYoutube != null && widget.recipe.strYoutube!.isNotEmpty)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final Uri url = Uri.parse(widget.recipe.strYoutube!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not launch ${widget.recipe.strYoutube}')),
                          );
                        }
                      },
                      child: Text('Watch on YouTube'),
                    ),
                  ),
                SizedBox(width: 10), // Add some space between the buttons
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await toggleSave();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isSaved ? 'Recipe saved!' : 'Recipe unsaved!')),
                      );
                    },
                    child: Text(isSaved ? 'Saved' : 'Save Recipe'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
