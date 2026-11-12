import 'package:common_pantry/features/recipes/data/models/meal_details.dart';
import 'package:common_pantry/features/recipes/data/models/recipe.dart';
import 'package:common_pantry/features/recipes/data/models/recipe_match_response.dart';
import 'package:common_pantry/features/recipes/data/repositories/recipe_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RecipeController extends ChangeNotifier {
  RecipeController(this._repository);

  final RecipeRepository _repository;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  bool _isDetailsLoading = false;
  String? _detailsErrorMessage;
  MealDetails? _mealDetails;

  String _productName = '';
  List<Recipe> _recipes = [];
  List<Map<String, dynamic>> _ingredients = [];

  bool get isLoading => _isLoading;

  bool get hasLoaded => _hasLoaded;

  String? get errorMessage => _errorMessage;

  String get productName => _productName;

  List<Recipe> get recipes => _recipes;

  List<Map<String, dynamic>> get ingredients => _ingredients;

  bool get isDetailsLoading => _isDetailsLoading;

  String? get detailsErrorMessage => _detailsErrorMessage;

  MealDetails? get mealDetails => _mealDetails;

  Future<void> load(String productName) async {
    _productName = productName;
    _isLoading = true;
    _hasLoaded = false;
    _errorMessage = null;
    _recipes = [];
    notifyListeners();

    try {
      final RecipeMatchResponse response = await _repository.getRecipes(productName);

      _recipes = response.recipes;
      _ingredients = response.ingredients;
      _hasLoaded = true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data is Map
          ? (e.response?.data['detail']?.toString() ?? 'Unable to load recipes.')
          : 'Unable to connect to the server.';
    } on FormatException {
      _errorMessage = 'Invalid response from the server.';
    } catch (_) {
      _errorMessage = 'Something went wrong.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMealDetails(String mealId) async {
    _isDetailsLoading = true;
    _detailsErrorMessage = null;
    _mealDetails = null;
    notifyListeners();

    try {
      _mealDetails = await _repository.getMealDetails(mealId);
    } on DioException {
      _detailsErrorMessage = 'Unable to connect to TheMealDB.';
    } on FormatException {
      _detailsErrorMessage = 'Recipe not found or invalid response.';
    } catch (_) {
      _detailsErrorMessage = 'Something went wrong.';
    } finally {
      _isDetailsLoading = false;
      notifyListeners();
    }
  }
}
