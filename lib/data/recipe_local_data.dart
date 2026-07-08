import '../models/ingredient_model.dart';
import '../models/recipe_model.dart';

class RecipeLocalMeta {
  const RecipeLocalMeta({
    required this.slug,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.isVegetarian,
    required this.ingredients,
    this.prepTime = '25 min',
    this.cookTime = '1 hr',
    this.feeds = '2',
  });

  final String slug;
  final String name;
  final String description;
  final String imageAsset;
  final bool isVegetarian;
  final List<IngredientModel> ingredients;
  final String prepTime;
  final String cookTime;
  final String feeds;
}

const Map<int, RecipeLocalMeta> recipeMetaByAlbumId = {
  1: RecipeLocalMeta(
    slug: 'sushi',
    name: 'Sushi',
    description:
        'Sushi is a Japanese dish fundamentally defined as vinegared rice (shari or sumeshi) paired with toppings or fillings (neta), such as raw or cooked seafood, vegetables, and egg, often wrapped in seaweed.',
    imageAsset: 'images/sushi.jpg',
    isVegetarian: false,
    prepTime: '25 min',
    cookTime: '1 hr',
    feeds: '4-6',
    ingredients: [
      IngredientModel(name: 'sushi rice', baseQuantity: 200, unit: 'g'),
      IngredientModel(name: 'rice vinegar', baseQuantity: 30, unit: 'ml'),
      IngredientModel(name: 'nori sheets', baseQuantity: 4, unit: ''),
      IngredientModel(name: 'salmon fillet', baseQuantity: 150, unit: 'g'),
      IngredientModel(name: 'cucumber', baseQuantity: 1, unit: ''),
    ],
  ),
  2: RecipeLocalMeta(
    slug: 'stir-fry',
    name: 'Vegetable Stir Fry',
    description:
        'A quick vegetarian stir fry with crisp vegetables in a savory garlic-ginger sauce.',
    imageAsset: 'images/VegetableStirFry.jpg',
    isVegetarian: true,
    prepTime: '15 min',
    cookTime: '10 min',
    feeds: '2',
    ingredients: [
      IngredientModel(name: 'broccoli', baseQuantity: 150, unit: 'g'),
      IngredientModel(name: 'bell pepper', baseQuantity: 1, unit: ''),
      IngredientModel(name: 'soy sauce', baseQuantity: 2, unit: ' tbsp'),
      IngredientModel(name: 'garlic cloves', baseQuantity: 2, unit: ''),
    ],
  ),
  3: RecipeLocalMeta(
    slug: 'pizza',
    name: 'Margherita Pizza',
    description:
        'Classic Neapolitan-style pizza with tomato, fresh mozzarella, and basil.',
    imageAsset: 'images/margherita.jpg',
    isVegetarian: true,
    prepTime: '20 min',
    cookTime: '12 min',
    feeds: '2',
    ingredients: [
      IngredientModel(name: 'pizza dough', baseQuantity: 250, unit: 'g'),
      IngredientModel(name: 'tomato sauce', baseQuantity: 100, unit: 'g'),
      IngredientModel(name: 'mozzarella', baseQuantity: 125, unit: 'g'),
      IngredientModel(name: 'fresh basil', baseQuantity: 8, unit: ' leaves'),
    ],
  ),
};

List<RecipeModel> localRecipes() {
  return recipeMetaByAlbumId.entries.map((entry) {
    final meta = entry.value;
    return RecipeModel(
      id: meta.slug,
      name: meta.name,
      description: meta.description,
      imageAsset: meta.imageAsset,
      isVegetarian: meta.isVegetarian,
      ingredients: meta.ingredients,
      prepTime: meta.prepTime,
      cookTime: meta.cookTime,
      feeds: meta.feeds,
    );
  }).toList();
}

/// Default recipes (Sushi, Stir Fry, Pizza) prepared for Firestore seeding.
List<RecipeModel> firestoreSeedRecipes(String uid) {
  return localRecipes()
      .map((recipe) => recipe.copyWith(createdBy: uid, favoritedBy: const []))
      .toList();
}
