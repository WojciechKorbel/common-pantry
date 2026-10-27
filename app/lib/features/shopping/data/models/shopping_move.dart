/// A bought shopping item to move to the pantry, with one expiry date per package.
class ShoppingMove {
  const ShoppingMove({
    required this.itemId,
    required this.expiryDates,
    this.brand,
  });

  final int itemId;
  final List<DateTime> expiryDates;
  final String? brand;
}
