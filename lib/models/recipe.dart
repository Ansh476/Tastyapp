class Recipe {
  final String idMeal;
  final String strMeal;
  final String strMealThumb;
  final String strInstructions;
  final String? strYoutube;
  final String strArea;
  final List<Ingredient> ingredients;

  Recipe({
    required this.idMeal,
    required this.strMeal,
    required this.strMealThumb,
    required this.strInstructions,
    this.strYoutube,
    required this.strArea,
    required this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<Ingredient> ingredientsList = [];
    for (int i = 1; i <= 20; i++) {
      String? ingredient = json['strIngredient$i'];
      String? measure = json['strMeasure$i'];

      if (ingredient != null && ingredient.isNotEmpty) {
        ingredientsList.add(Ingredient(name: ingredient, measure: measure ?? ''));
      }
    }

    return Recipe(
      idMeal: json['idMeal'] ?? '',
      strMeal: json['strMeal'] ?? '',
      strMealThumb: json['strMealThumb'] ?? '',
      strInstructions: json['strInstructions'] ?? '',
      strYoutube: json['strYoutube'],
      strArea: json['strArea'] ?? '',
      ingredients: ingredientsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idMeal': idMeal,
      'strMeal': strMeal,
      'strMealThumb': strMealThumb,
      'strInstructions': strInstructions,
      'strYoutube': strYoutube,
      'strArea': strArea,
    };
  }
}

class Ingredient {
  final String name;
  final String measure;

  Ingredient({required this.name, required this.measure});
}