import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape of GET /api/households/{id}/details/.
Map<String, dynamic> _json() => {
  'id': 1,
  'name': 'Akademik',
  'invite_code': 'K7Q2MX',
  'created_at': '2026-10-16T19:42:36.374415+02:00',
  'role': 'owner',
  'members': [
    {
      'user_id': 1,
      'username': 'user1',
      'role': 'owner',
      'joined_at': '2026-10-16T19:42:36.374415+02:00',
      'is_me': true,
    },
    {
      'user_id': 2,
      'username': 'user2',
      'role': 'member',
      'joined_at': '2026-10-20T08:00:00+02:00',
      'is_me': false,
    },
  ],
};

void main() {
  group('HouseholdDetails.fromJson', () {
    test('parses the household and its members', () {
      final details = HouseholdDetails.fromJson(_json());

      expect(details.id, 1);
      expect(details.name, 'Akademik');
      expect(details.inviteCode, 'K7Q2MX');
      expect(details.isOwner, isTrue);
      expect(details.createdAt, isNotNull);

      expect(details.members.map((member) => member.username), ['user1', 'user2']);
      expect(details.members.first.isMe, isTrue);
      expect(details.members.first.isOwner, isTrue);
      expect(details.members.last.userId, 2);
      expect(details.members.last.isOwner, isFalse);
      expect(details.members.last.joinedAt?.toUtc(), DateTime.utc(2026, 10, 20, 6));
    });

    test('uses defaults when optional fields are missing', () {
      final details = HouseholdDetails.fromJson({'id': 1, 'name': 'Akademik'});

      expect(details.inviteCode, '');
      expect(details.role, 'member');
      expect(details.isOwner, isFalse);
      expect(details.createdAt, isNull);
      expect(details.members, isEmpty);
    });

    test('member without is_me is not the current user and an invalid date is ignored', () {
      final member = HouseholdMember.fromJson({
        'user_id': 3,
        'username': 'user3',
        'role': 'member',
        'joined_at': 'not a date',
      });

      expect(member.isMe, isFalse);
      expect(member.joinedAt, isNull);
    });

    test('throws when the id is missing', () {
      final json = _json()..remove('id');

      expect(() => HouseholdDetails.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}