import 'package:common_pantry/features/stats/data/models/food_waste_statistics.dart';
import 'package:common_pantry/features/stats/data/repositories/statistics_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class StatisticsController extends ChangeNotifier {
  StatisticsController(this._repository, {
    required this.householdId,
  });

  final StatisticsRepository _repository;
  final int householdId;

  static const periods = ['7d', '30d', '12m', 'all'];

  String _period = '30d';

  String get period => _period;

  FoodWasteStatistics? _statistics;

  FoodWasteStatistics? get statistics => _statistics;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _hasLoaded = false;

  bool get hasLoaded => _hasLoaded;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _statistics = await _repository.getFoodWasteStatistics(
        householdId,
        period: _period,
      );
      _hasLoaded = true;
    } on DioException catch (e) {
      _errorMessage = _messageFor(e);
    } on FormatException {
      _errorMessage = 'Invalid statistics response.';
    } catch (_) {
      _errorMessage = 'Something went wrong. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPeriod(String period) async {
    if (!periods.contains(period) || period == _period) return;

    _period = period;
    await load();
  }

  Future<void> refresh() => load();

  String _messageFor(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
      'Cannot reach the server. Check your connection.',
      _ =>
      switch (e.response?.statusCode) {
        400 => 'Invalid statistics period.',
        401 => 'Your session has expired. Log in again.',
        403 => 'You do not have access to this household.',
        404 => 'Household not found.',
        _ => 'Something went wrong. Try again.',
      },
    };
  }
}
