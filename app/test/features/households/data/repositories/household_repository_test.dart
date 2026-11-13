import 'package:common_pantry/features/households/data/repositories/household_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http.dart';

const _akademik = {'id': 1, 'name': 'Akademik', 'invite_code': 'K7Q2MX', 'role': 'owner'};

void main() {
  late FakeHttpAdapter server;
  late HouseholdsRepository repository;

  setUp(() {
    server = FakeHttpAdapter();
    repository = HouseholdsRepository(fakeApiClient(server));
  });

  test('loads the households of the user', () async {
    server.answer = (_) => (status: 200, body: [_akademik]);

    final households = await repository.getHouseholds();

    expect(server.calls, [('GET', '/api/households/')]);
    expect(households.single.name, 'Akademik');
  });

  test('creating a household sends its name', () async {
    server.answer = (_) => (status: 201, body: _akademik);

    final household = await repository.createHousehold(name: 'Akademik');

    expect(server.calls, [('POST', '/api/households/')]);
    expect(server.requests.single.data, {'name': 'Akademik'});
    expect(household.inviteCode, 'K7Q2MX');
  });

  test('joining sends the invite code and reads the joined household', () async {
    server.answer = (_) => (status: 200, body: {'detail': 'Joined.', 'household': _akademik});

    final household = await repository.joinHousehold(inviteCode: 'K7Q2MX');

    expect(server.calls, [('POST', '/api/households/join/')]);
    expect(server.requests.single.data, {'invite_code': 'K7Q2MX'});
    expect(household.id, 1);
  });
}
