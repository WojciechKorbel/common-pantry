import 'package:common_pantry/core/utils/expiry_date_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ref = DateTime(2026, 11, 13);

  group('ExpiryDateParser', () {
    test('parses DD.MM.YYYY format', () {
      final dates = ExpiryDateParser.extractDates(
        'Najlepiej spożyć przed: 24.12.2026 L1234',
        referenceDate: ref,
      );
      expect(dates, [DateTime(2026, 12, 24)]);
    });

    test('parses YYYY-MM-DD and DD/MM/YY formats', () {
      final dates = ExpiryDateParser.extractDates(
        'PROD: 2026-10-01 EXP: 15/05/27',
        referenceDate: ref,
      );
      expect(dates, [DateTime(2026, 10, 1), DateTime(2027, 5, 15)]);
    });

    test('parses text month names in English and Polish', () {
      final dates = ExpiryDateParser.extractDates(
        'BEST BEFORE 08 MAR 2027 / 12 LIS 2026',
        referenceDate: ref,
      );
      expect(dates, [DateTime(2026, 11, 12), DateTime(2027, 3, 8)]);
    });

    test('falls back to MM/YYYY as end of month', () {
      final dates = ExpiryDateParser.extractDates(
        'EXP 08/2027',
        referenceDate: ref,
      );
      expect(dates, [DateTime(2027, 8, 31)]);
    });

    test('ignores invalid calendar dates and out-of-range years', () {
      final dates = ExpiryDateParser.extractDates(
        '31.02.2026 12.12.1999 01.01.2099',
        referenceDate: ref,
      );
      expect(dates, isEmpty);
    });
  });
}
