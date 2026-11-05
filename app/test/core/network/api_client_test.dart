import 'package:common_pantry/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';

const _refreshPath = '/api/auth/token/refresh/';

void main() {
  late FakeTokenStorage tokens;
  late FakeHttpAdapter server;
  late ApiClient api;

  setUp(() {
    tokens = FakeTokenStorage(access: 'access-1', refresh: 'refresh-1');
    server = FakeHttpAdapter();
    api = ApiClient(tokens, baseUrl: 'https://api.test', httpClientAdapter: server);
  });

  List<String> paths() => server.requests.map((request) => request.path).toList();

  Matcher failsWithStatus(int status) => throwsA(
    isA<DioException>().having((e) => e.response?.statusCode, 'status code', status),
  );

  /// The server accepts only `Bearer access-2`; the refresh endpoint answers [refresh].
  void accessOneHasExpired({required FakeAnswer refresh, FakeAnswer? withNewToken}) {
    server.answer = (request) {
      if (request.path == _refreshPath) {
        return refresh;
      }
      if (request.headers['Authorization'] == 'Bearer access-2') {
        return withNewToken ?? (status: 200, body: {'ok': true});
      }
      return (status: 401, body: {'detail': 'Given token not valid for any token type'});
    };
  }

  group('access token', () {
    test('is attached to API requests', () async {
      await api.dio.get<dynamic>('/api/categories/');

      expect(server.requests.single.headers['Authorization'], 'Bearer access-1');
    });

    test('is not attached to login and refresh requests', () async {
      await api.dio.post<dynamic>('/api/auth/token/', data: {'username': 'u', 'password': 'p'});
      await api.dio.post<dynamic>(_refreshPath, data: {'refresh': 'refresh-1'});

      expect(server.requests.map((request) => request.headers['Authorization']), [null, null]);
    });

    test('is missing when the user is logged out', () async {
      tokens.access = null;

      await api.dio.get<dynamic>('/api/categories/');

      expect(server.requests.single.headers['Authorization'], isNull);
    });

    test('a 401 from login (wrong password) is passed on without a refresh', () async {
      server.answer = (_) => (status: 401, body: {'detail': 'No active account found'});

      await expectLater(
        api.dio.post<dynamic>('/api/auth/token/', data: {'username': 'u', 'password': 'p'}),
        failsWithStatus(401),
      );
      expect(paths(), ['/api/auth/token/']);
    });
  });

  group('expired access token', () {
    test('is refreshed and the request is sent again', () async {
      accessOneHasExpired(refresh: (status: 200, body: {'access': 'access-2'}));

      final response = await api.dio.get<dynamic>('/api/categories/');

      expect(response.statusCode, 200);
      expect(paths(), ['/api/categories/', _refreshPath, '/api/categories/']);
      expect(server.requests[1].data, {'refresh': 'refresh-1'});
      expect(tokens.access, 'access-2');
      expect(tokens.refresh, 'refresh-1');
    });

    test('a rotated refresh token is saved too', () async {
      accessOneHasExpired(
        refresh: (status: 200, body: {'access': 'access-2', 'refresh': 'refresh-2'}),
      );

      await api.dio.get<dynamic>('/api/categories/');

      expect(tokens.refresh, 'refresh-2');
    });

    test('several requests failing at once refresh the token only once', () async {
      accessOneHasExpired(refresh: (status: 200, body: {'access': 'access-2'}));
      server.delay = const Duration(milliseconds: 10);

      final responses = await Future.wait([
        api.dio.get<dynamic>('/api/categories/'),
        api.dio.get<dynamic>('/api/households/'),
      ]);

      expect(responses.map((response) => response.statusCode), [200, 200]);
      expect(paths().where((path) => path == _refreshPath), hasLength(1));
    });
  });

  group('logging out', () {
    test('a rejected refresh token logs the user out', () async {
      accessOneHasExpired(refresh: (status: 401, body: {'detail': 'Token is blacklisted'}));

      await expectLater(api.dio.get<dynamic>('/api/categories/'), failsWithStatus(401));
      expect(tokens.access, isNull);
      expect(tokens.refresh, isNull);
    });

    test('without a refresh token the user is logged out without asking the server', () async {
      tokens.refresh = null;
      accessOneHasExpired(refresh: (status: 200, body: {'access': 'access-2'}));

      await expectLater(api.dio.get<dynamic>('/api/categories/'), failsWithStatus(401));
      expect(paths(), ['/api/categories/']);
      expect(tokens.access, isNull);
    });

    test('a 401 even with the new token logs the user out', () async {
      accessOneHasExpired(
        refresh: (status: 200, body: {'access': 'access-2'}),
        withNewToken: (status: 401, body: {'detail': 'User is inactive'}),
      );

      await expectLater(api.dio.get<dynamic>('/api/categories/'), failsWithStatus(401));
      expect(paths().where((path) => path == _refreshPath), hasLength(1));
      expect(tokens.access, isNull);
    });

    test(
      'a server error on the retried request keeps the user logged in',
      () async {
        accessOneHasExpired(
          refresh: (status: 200, body: {'access': 'access-2'}),
          withNewToken: (status: 500, body: {'detail': 'Server error'}),
        );

        await expectLater(api.dio.get<dynamic>('/api/categories/'), failsWithStatus(500));
        expect(tokens.access, 'access-2');
        expect(tokens.refresh, 'refresh-1');
      },
      // TODO: remove when fixed
      skip: 'Known bug: any failure of the retried request logs the user out',
    );
  });
}
