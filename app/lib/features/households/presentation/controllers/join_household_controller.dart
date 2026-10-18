import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/data/repositories/household_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class JoinHouseholdController extends ChangeNotifier {
  JoinHouseholdController(this._repository);

  final HouseholdsRepository _repository;

  static const int codeLength = 6;

  late final List<TextEditingController> codeControllers = List.generate(
    codeLength,
    (_) => TextEditingController(),
  );

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _hasError = false;

  bool get hasError => _hasError;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Household? _joinedHousehold;

  Household? get joinedHousehold => _joinedHousehold;

  String get code => codeControllers.map((controller) => controller.text).join();

  void onDigitChanged(String value, int index) {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearCode() {
    for (final controller in codeControllers) {
      controller.clear();
    }

    _hasError = false;
    _errorMessage = null;
    _joinedHousehold = null;

    notifyListeners();
  }

  bool validateCode() {
    final isComplete =
        code.length == codeLength &&
        codeControllers.every(
          (controller) => controller.text.isNotEmpty,
        );

    _hasError = !isComplete;
    _errorMessage = isComplete ? null : 'Please enter all 6 digits of the code.';

    notifyListeners();
    return isComplete;
  }

  Future<bool> joinHousehold() async {
    if (!validateCode()) return false;

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _joinedHousehold = null;
    notifyListeners();

    try {
      _joinedHousehold = await _repository.joinHousehold(
        inviteCode: code,
      );
      return true;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      final detail = responseData is Map ? responseData['detail']?.toString() : null;

      if (statusCode == 404) {
        _errorMessage = detail ?? 'Invalid invitation code.';
      } else if (statusCode == 409) {
        _errorMessage = detail ?? 'You are already a member of this household.';
      } else if (statusCode == 400) {
        _errorMessage = detail ?? 'Please enter a valid invitation code.';
      } else {
        _errorMessage = detail ?? 'Failed to join household. Please try again.';
      }

      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final controller in codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
