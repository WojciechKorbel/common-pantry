import 'dart:convert';
import 'dart:typed_data';

import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

typedef FakeAnswer = ({int status, Object? body});

/// What a request looked like when it reached the fake server.
typedef FakeRequest = ({
  String method,
  String path,
  Map<String, dynamic> query,
  Map<String, dynamic> headers,
  Object? data,
});

/// Replaces the network under [Dio]: records requests and answers with [answer].
class FakeHttpAdapter implements HttpClientAdapter {
  FakeAnswer Function(RequestOptions request) answer = (_) =>
      (status: 200, body: <String, dynamic>{});

  /// Delay of every answer, to keep requests "in flight" at the same time.
  Duration delay = Duration.zero;

  final requests = <FakeRequest>[];

  /// (method, path) of every request, in order.
  List<(String, String)> get calls =>
      requests.map((request) => (request.method, request.path)).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((
      method: options.method,
      path: options.path,
      query: Map.of(options.queryParameters),
      headers: Map.of(options.headers),
      data: options.data,
    ));
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final (:status, :body) = answer(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Keeps tokens in memory instead of the Android keystore.
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({this.access, this.refresh});

  String? access;
  String? refresh;

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> saveAccessToken(String access) async {
    this.access = access;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

/// [ApiClient] talking to [server] instead of the network, with a logged-in user.
ApiClient fakeApiClient(FakeHttpAdapter server, {FakeTokenStorage? tokens}) => ApiClient(
  tokens ?? FakeTokenStorage(access: 'access-1', refresh: 'refresh-1'),
  baseUrl: 'https://api.test',
  httpClientAdapter: server,
);
