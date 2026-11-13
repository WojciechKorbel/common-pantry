import 'package:common_pantry/features/auth/data/models/auth_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthTokens.fromJson', () {
    test('parses the login response', () {
      final tokens = AuthTokens.fromJson({'access': 'access-token', 'refresh': 'refresh-token'});

      expect(tokens.access, 'access-token');
      expect(tokens.refresh, 'refresh-token');
    });

    test('throws FormatException when a token is missing, empty or not a string', () {
      final invalidResponses = <Map<String, dynamic>>[
        {'access': 'access-token'},
        {'access': '', 'refresh': 'refresh-token'},
        {'access': 'access-token', 'refresh': 42},
        {'detail': 'No active account found with the given credentials'},
      ];

      for (final json in invalidResponses) {
        expect(() => AuthTokens.fromJson(json), throwsFormatException, reason: '$json');
      }
    });
  });
}