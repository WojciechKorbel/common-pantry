import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Household.fromJson', () {
    test('parses a household from the households list', () {
      final household = Household.fromJson({
        'id': 1,
        'name': 'Akademik',
        'invite_code': 'K7Q2MX',
        'created_at': '2026-10-16T19:42:36.374415+02:00',
        'role': 'owner',
      });

      expect(household.id, 1);
      expect(household.name, 'Akademik');
      expect(household.inviteCode, 'K7Q2MX');
      expect(household.role, 'owner');
      expect(household.createdAt?.toUtc(), DateTime.utc(2026, 10, 16, 17, 42, 36, 374, 415));
    });

    test('accepts missing optional fields', () {
      final household = Household.fromJson({'id': 2, 'name': 'Dom'});

      expect(household.inviteCode, isNull);
      expect(household.role, isNull);
      expect(household.createdAt, isNull);
    });

    test('throws when the name is missing', () {
      expect(() => Household.fromJson({'id': 2}), throwsA(isA<TypeError>()));
    });
  });
}