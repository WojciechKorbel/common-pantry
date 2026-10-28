import 'package:common_pantry/features/pantry/data/models/user_summary.dart';

/// One line on the household shopping list.
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isBought,
    required this.addedBy,
    required this.boughtBy,
  });

  static const _maxPackages = 20;

  final int id;
  final String name;
  final double quantity;
  final String unit;
  final bool isBought;

  final UserSummary? addedBy;
  final UserSummary? boughtBy;

  bool get isWholeQuantity => quantity == quantity.roundToDouble();

  bool get showQuantity => !(unit == 'pcs' && quantity == 1);

  String get quantityLabel => '${isWholeQuantity ? quantity.toInt() : quantity} $unit';

  int get packageCount {
    if (unit == 'pcs' && isWholeQuantity) {
      return quantity.toInt().clamp(1, _maxPackages).toInt();
    }
    return 1;
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    if (json case {
      'id': final int id,
      'name': final String name,
      'unit': final String unit,
      'is_bought': final bool isBought,
    }) {
      return ShoppingItem(
        id: id,
        name: name,
        quantity: switch (json['quantity']) {
          final num value => value.toDouble(),
          final String value => double.tryParse(value) ?? 1.0,
          _ => 1.0,
        },
        unit: unit,
        isBought: isBought,
        addedBy: switch (json['added_by']) {
          final Map<String, dynamic> user => UserSummary.fromJson(user),
          _ => null,
        },
        boughtBy: switch (json['bought_by']) {
          final Map<String, dynamic> user => UserSummary.fromJson(user),
          _ => null,
        },
      );
    }
    throw const FormatException('Invalid shopping item');
  }
}
