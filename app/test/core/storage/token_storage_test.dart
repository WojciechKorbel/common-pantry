import 'package:common_pantry/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = TokenStorage();
  });

  Future<String?> raw(String key) => const FlutterSecureStorage().read(key: key);

  test('has no tokens at the start', () async {
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
  });

  test('saveTokens stores both tokens', () async {
    await storage.saveTokens(access: 'access-1', refresh: 'refresh-1');

    expect(await storage.getAccessToken(), 'access-1');
    expect(await storage.getRefreshToken(), 'refresh-1');
  });

  test('tokens are kept under stable keys', () async {
    await storage.saveTokens(access: 'access-1', refresh: 'refresh-1');

    expect(await raw('access_token'), 'access-1');
    expect(await raw('refresh_token'), 'refresh-1');
  });

  test('saveAccessToken replaces only the access token', () async {
    await storage.saveTokens(access: 'access-1', refresh: 'refresh-1');

    await storage.saveAccessToken('access-2');

    expect(await storage.getAccessToken(), 'access-2');
    expect(await storage.getRefreshToken(), 'refresh-1');
  });

  test('saveTokens overwrites older tokens', () async {
    await storage.saveTokens(access: 'access-1', refresh: 'refresh-1');

    await storage.saveTokens(access: 'access-2', refresh: 'refresh-2');

    expect(await storage.getAccessToken(), 'access-2');
    expect(await storage.getRefreshToken(), 'refresh-2');
  });

  test('clear removes both tokens', () async {
    await storage.saveTokens(access: 'access-1', refresh: 'refresh-1');

    await storage.clear();

    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
  });

  test('clear on empty storage does not fail', () async {
    await storage.clear();

    expect(await storage.getAccessToken(), isNull);
  });

  test('uses the storage that was passed in', () async {
    const custom = FlutterSecureStorage();
    final other = TokenStorage(storage: custom);

    await other.saveAccessToken('shared');

    expect(await storage.getAccessToken(), 'shared');
  });
}
