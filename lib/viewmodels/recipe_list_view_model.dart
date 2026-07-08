import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/recipe_model.dart';
import '../services/recipe_firestore_service.dart';

enum CategoryFilter { all, vegetarian, nonVegetarian }

class RecipeListViewModel extends ChangeNotifier {
  RecipeListViewModel() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  final _service = RecipeFirestoreService.instance;

  List<RecipeModel> _allRecipes = [];
  StreamSubscription<List<RecipeModel>>? _sub;
  StreamSubscription<User?>? _authSub;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  CategoryFilter _categoryFilter = CategoryFilter.all;
  CategoryFilter get categoryFilter => _categoryFilter;

  // ── Getters ───────────────────────────────────────────────────────────────

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Public accessor for the current user's UID (needed by list screen widgets).
  String get currentUid => _currentUid;

  List<RecipeModel> get displayedRecipes {
    var list = _allRecipes;

    // Category filter
    if (_categoryFilter == CategoryFilter.vegetarian) {
      list = list.where((r) => r.isVegetarian).toList();
    } else if (_categoryFilter == CategoryFilter.nonVegetarian) {
      list = list.where((r) => !r.isVegetarian).toList();
    }

    // Search filter
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((r) =>
              r.name.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  List<RecipeModel> get favoriteRecipes =>
      _allRecipes.where((r) => r.isFavoritedBy(_currentUid)).toList();

  int get favoriteCount => favoriteRecipes.length;

  int get recipeCount => _allRecipes.length;

  int get vegetarianCount => _allRecipes.where((r) => r.isVegetarian).length;

  RecipeModel? recipeById(String id) {
    for (final recipe in _allRecipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  // ── Auth + Firestore init ─────────────────────────────────────────────────

  Future<void> _onAuthChanged(User? user) async {
    await _sub?.cancel();
    _sub = null;

    if (user == null) {
      _allRecipes = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.seedIfEmpty();
      _sub = _service.recipesStream().listen(
        (recipes) {
          _allRecipes = recipes;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (Object error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(CategoryFilter filter) {
    _categoryFilter = filter;
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addRecipe(RecipeModel recipe) async {
    await _service.addRecipe(recipe);
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    await _service.updateRecipe(recipe);
  }

  Future<void> deleteRecipe(String id) async {
    await _service.deleteRecipe(id);
  }

  // ── Favorites ─────────────────────────────────────────────────────────────

  Future<void> toggleFavorite(RecipeModel recipe) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    final index = _allRecipes.indexWhere((r) => r.id == recipe.id);
    if (index == -1) return;

    final current = _allRecipes[index];
    final optimisticFavorites = List<String>.from(current.favoritedBy);
    if (optimisticFavorites.contains(uid)) {
      optimisticFavorites.remove(uid);
    } else {
      optimisticFavorites.add(uid);
    }

    _allRecipes[index] = current.copyWith(favoritedBy: optimisticFavorites);
    notifyListeners();

    try {
      await _service.toggleFavorite(current.id);
    } catch (e) {
      _allRecipes[index] = current;
      notifyListeners();
      rethrow;
    }
  }

  void notifyRecipesChanged() => notifyListeners();

  @override
  void dispose() {
    _authSub?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
