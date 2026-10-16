import 'package:common_pantry/features/pantry/domain/expiry_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 16, 22);

  test('expiryStatusOf: yesterday expired, up to 3 days soon, later fresh', () {
    expect(expiryStatusOf(DateTime(2026, 10, 15), today), ExpiryStatus.expired);
    expect(expiryStatusOf(DateTime(2026, 10, 16), today), ExpiryStatus.soon);
    expect(expiryStatusOf(DateTime(2026, 10, 19), today), ExpiryStatus.soon);
    expect(expiryStatusOf(DateTime(2026, 10, 20), today), ExpiryStatus.fresh);
  });

  test('daysUntil counts calendar days across the daylight saving change', () {
    expect(daysUntil(DateTime(2026, 10, 27), DateTime(2026, 10, 24, 23, 30)), 3);
  });
}
