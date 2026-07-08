import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/recipe_local_data.dart';
import '../models/recipe_model.dart';

/// All Firestore interactions for recipes live here.
class RecipeFirestoreService {
  RecipeFirestoreService._();
  static final RecipeFirestoreService instance = RecipeFirestoreService._();

  final _col = FirebaseFirestore.instance.collection('recipes');

  Stream<List<RecipeModel>> recipesStream() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RecipeModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<String> addRecipe(RecipeModel recipe) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final data = recipe.toMap();
    data['createdBy'] = uid;
    data['favoritedBy'] = <String>[];
    data['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _col.add(data);
    return ref.id;
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    final data = recipe.toMap()
      ..remove('createdAt')
      ..remove('createdBy')
      ..remove('favoritedBy');
    await _col.doc(recipe.id).update(data);
  }

  Future<void> deleteRecipe(String id) async {
    await _col.doc(id).delete();
  }

  /// Toggles favorite state using a transaction so the latest data is always used.
  Future<void> toggleFavorite(String recipeId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('You must be signed in to favorite recipes.');
    }

    final docRef = _col.doc(recipeId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw StateError('Recipe not found.');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final favorites = List<String>.from(
        (data['favoritedBy'] as List?)?.whereType<String>() ?? const [],
      );

      if (favorites.contains(uid)) {
        favorites.remove(uid);
      } else {
        favorites.add(uid);
      }

      transaction.update(docRef, {'favoritedBy': favorites});
    });
  }

  Future<void> seedIfEmpty() async {
    final snap = await _col.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final seeds = firestoreSeedRecipes(uid);
    final batch = FirebaseFirestore.instance.batch();
    for (final recipe in seeds) {
      final ref = _col.doc();
      batch.set(ref, recipe.toMap());
    }
    await batch.commit();
  }
}
