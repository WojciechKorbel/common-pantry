import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/data/models/pantry_group_item.dart';
import 'package:common_pantry/features/pantry/data/models/product.dart';
import 'package:common_pantry/features/pantry/data/models/product_category.dart';
import 'package:common_pantry/features/pantry/data/models/user_summary.dart';
import 'package:common_pantry/features/shopping/data/models/shopping_item.dart';
import 'package:common_pantry/features/stats/data/models/food_waste_statistics.dart';
import 'package:dio/dio.dart';

const dairy = ProductCategory(id: 4, name: 'Dairy');
const readyMeals = ProductCategory(id: 3, name: 'Ready meals & soups');

const home = Household(id: 1, name: 'Akademik');

const homeDetails = HouseholdDetails(
  id: 1,
  name: 'Akademik',
  inviteCode: 'K7Q2MX',
  role: 'owner',
  members: [],
);

PantryGroup aPantryGroup({
  int id = 1,
  String name = 'Serek wiejski',
  ProductCategory? category,
  int itemCount = 1,
  DateTime? earliestExpiry,
  String? expiryStatus,
  List<PantryGroupItem> items = const [],
}) => PantryGroup(
  id: id,
  name: name,
  brand: null,
  imageUrl: null,
  packageSize: '',
  category: category,
  itemCount: itemCount,
  earliestExpiry: earliestExpiry ?? DateTime(2026, 11, 20),
  expiryStatus: expiryStatus,
  items: items,
);

PantryGroupItem aPantryGroupItem({
  int id = 1,
  DateTime? expiryDate,
  String? addedBy = 'user1',
  String origin = 'purchased',
}) => PantryGroupItem(
  id: id,
  expiryDate: expiryDate ?? DateTime(2026, 11, 20),
  origin: origin,
  addedBy: addedBy == null ? null : UserSummary(id: 1, username: addedBy),
  createdAt: DateTime(2026, 11, 1),
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

FoodWasteStatistics aStatistics({String period = '30d'}) => FoodWasteStatistics(
  period: period,
  summary: const StatisticsSummary(
    activeCount: 0,
    eatenCount: 0,
    wastedCount: 0,
    wastePercentage: 0,
  ),
  timeline: const [],
  categories: const [],
  topWastedProducts: const [],
  expiry: const ExpiryStatistics(expired: 0, notExpired: 0),
);

/// The server answered with [statusCode] and an optional JSON body.
DioException serverError(int statusCode, {Object? data}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/'),
    statusCode: statusCode,
    data: data,
  ),
);

/// The server could not be reached at all.
DioException connectionError() => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.connectionError,
);
