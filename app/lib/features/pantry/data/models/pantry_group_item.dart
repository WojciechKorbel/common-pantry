import 'package:common_pantry/features/pantry/data/models/user_summary.dart';

/// One package of a product in the pantry (a row under an expanded tile).
class PantryGroupItem {
  const PantryGroupItem({
    required this.id,
    required this.expiryDate,
    required this.addedBy,
    required this.createdAt,
  });

  final int id;
  final DateTime expiryDate;

  /// Null when the user who added the item no longer exists.
  final UserSummary? addedBy;
  final DateTime createdAt;

  factory PantryGroupItem.fromJson(Map<String, dynamic> json) {
    if (json case {
      'id': final int id,
      'expiry_date': final String expiryDate,
      'created_at': final String createdAt,
    }) {
      return PantryGroupItem(
        id: id,
        expiryDate: DateTime.parse(expiryDate),
        addedBy: switch (json['added_by']) {
          final Map<String, dynamic> user => UserSummary.fromJson(user),
          _ => null,
        },
        createdAt: DateTime.parse(createdAt),
      );
    }
    throw const FormatException('Invalid pantry item');
  }
}
