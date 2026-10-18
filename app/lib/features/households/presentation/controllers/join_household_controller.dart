import 'package:flutter/material.dart';

class JoinHouseholdController extends ChangeNotifier {
  static const int codeLength = 6;

  late final List<TextEditingController> codeControllers;

  bool _hasError = false;

  bool get hasError => _hasError;

  String get code => codeControllers.map((controller) => controller.text).join();

  JoinHouseholdController() {
    codeControllers = List.generate(
      codeLength,
      (_) => TextEditingController(),
    );
  }

  void onDigitChanged(String value, int index) {
    if (_hasError) {
      _hasError = false;
    }

    // Handle pasting a complete code.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

      for (var i = 0; i < codeLength; i++) {
        codeControllers[i].text = i < digits.length ? digits[i] : '';
      }
    }

    notifyListeners();
  }

  bool validateCode() {
    final isComplete =
        code.length == codeLength &&
        codeControllers.every(
          (controller) => controller.text.isNotEmpty,
        );

    _hasError = !isComplete;
    notifyListeners();

    return isComplete;
  }

  void clearError() {
    if (!_hasError) return;

    _hasError = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in codeControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}
