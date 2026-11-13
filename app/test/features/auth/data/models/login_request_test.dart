import 'package:common_pantry/features/auth/data/models/login_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson sends the fields expected by /api/auth/token/', () {
    const request = LoginRequest(username: 'user1', password: 'secret123');

    expect(request.toJson(), {'username': 'user1', 'password': 'secret123'});
  });
}