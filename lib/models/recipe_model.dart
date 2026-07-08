import 'package:cloud_firestore/cloud_firestore.dart';
import 'ingredient_model.dart';

class RecipeModel {
  RecipeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.ingredients,
    required this.isVegetarian,
    this.prepTime = '25 min',
    this.cookTime = '1 hr',
    this.feeds = '2',
    this.createdAt,
    this.createdBy = '',
    this.favoritedBy = const [],
  });

  final String id;
  final String name;
  final String description;
  final String imageAsset;
  final List<IngredientModel> ingredients;
  final bool isVegetarian;
  final String prepTime;
  final String cookTime;
  final String feeds;
  final Timestamp? createdAt;
  final String createdBy;
  final List<String> favoritedBy;

  /// Whether a specific user has favorited this recipe.
  bool isFavoritedBy(String uid) => favoritedBy.contains(uid);

  /// Deserialize from a Firestore document.
  factory RecipeModel.fromMap(String docId, Map<String, dynamic> map) {
    final rawIngredients = map['ingredients'];
    final ingredientList = <IngredientModel>[];
    if (rawIngredients is List) {
      for (final item in rawIngredients) {
        if (item is Map<String, dynamic>) {
          ingredientList.add(IngredientModel.fromMap(item));
        }
      }
    }

    final rawFavoritedBy = map['favoritedBy'];
    final favList = <String>[];
    if (rawFavoritedBy is List) {
      for (final uid in rawFavoritedBy) {
        if (uid is String) favList.add(uid);
      }
    }

    return RecipeModel(
      id: docId,
      name: (map['name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      imageAsset: (map['imageAsset'] as String?) ?? '',
      isVegetarian: (map['isVegetarian'] as bool?) ?? false,
      prepTime: (map['prepTime'] as String?) ?? '25 min',
      cookTime: (map['cookTime'] as String?) ?? '1 hr',
      feeds: (map['feeds'] as String?) ?? '2',
      ingredients: ingredientList,
      createdAt: map['createdAt'] as Timestamp?,
      createdBy: (map['createdBy'] as String?) ?? '',
      favoritedBy: favList,
    );
  }

  /// Serialize to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageAsset': imageAsset,
      'isVegetarian': isVegetarian,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'feeds': feeds,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'favoritedBy': favoritedBy,
    };
  }

  /// Returns a copy with updated fields.
  RecipeModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageAsset,
    List<IngredientModel>? ingredients,
    bool? isVegetarian,
    String? prepTime,
    String? cookTime,
    String? feeds,
    Timestamp? createdAt,
    String? createdBy,
    List<String>? favoritedBy,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageAsset: imageAsset ?? this.imageAsset,
      ingredients: ingredients ?? this.ingredients,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      feeds: feeds ?? this.feeds,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      favoritedBy: favoritedBy ?? this.favoritedBy,
    );
  }
}
