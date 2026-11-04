import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_item.dart';
import 'package:dio/dio.dart';

const dairy = ProductCategory(id: 4, name: 'Dairy');
const readyMeals = ProductCategory(id: 3, name: 'Ready meals & soups');

const home = Household(id: 1, name: 'Akademik');

PantryGroup aPantryGroup({
  int id = 1,
  String name = 'Serek wiejski',
  ProductCategory? category,
  int itemCount = 1,
  DateTime? earliestExpiry,
}) => PantryGroup(
  id: id,
  name: name,
  brand: null,
  imageUrl: null,
  packageSize: '',
  category: category,
  itemCount: itemCount,
  earliestExpiry: earliestExpiry ?? DateTime(2026, 11, 20),
  items: const [],
);

Product aProduct({
  int id = 1,
  String name = 'Serek wiejski',
  String? brand,
  ProductCategory? category,
  bool custom = false,
}) => Product(
  id: id,
  name: name,
  brand: brand,
  barcode: null,
  packageSize: '',
  imageUrl: null,
  category: category,
  productType: custom ? 'custom' : 'global',
);

ShoppingItem aShoppingItem({
  int id = 1,
  String name = 'Mleko',
  double quantity = 1,
  String unit = 'pcs',
  bool bought = false,
}) => ShoppingItem(
  id: id,
  name: name,
  quantity: quantity,
  unit: unit,
  isBought: bought,
  addedBy: null,
  boughtBy: null,
);

/// The server answered with [statusCode].
DioException serverError(int statusCode) => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/'),
    statusCode: statusCode,
  ),
);

/// The server could not be reached at all.
DioException connectionError() => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.connectionError,
);
