import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/ingredient_model.dart';
import '../models/recipe_model.dart';

class RecipeDetailViewModel extends ChangeNotifier {
  RecipeDetailViewModel(this.recipe, {this.onFavoriteChanged});

  RecipeModel recipe;
  final VoidCallback? onFavoriteChanged;
  int servingSize = 1;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool get isFavorite => recipe.isFavoritedBy(_currentUid);

  bool get isOwner =>
      recipe.createdBy.isNotEmpty && recipe.createdBy == _currentUid;

  List<IngredientModel> get ingredients => recipe.ingredients;

  List<String> get scaledIngredientLabels =>
      ingredients.map((i) => i.displayForServings(servingSize)).toList();

  void updateRecipe(RecipeModel updated) {
    recipe = updated;
    notifyListeners();
  }

  void incrementServings() {
    servingSize++;
    notifyListeners();
  }

  void decrementServings() {
    if (servingSize > 1) {
      servingSize--;
      notifyListeners();
    }
  }
}
