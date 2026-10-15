import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/core/storage/token_storage.dart';
import 'package:common_pantry/features/auth/data/controllers/login_controller.dart';
import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';

class Dependencies {
  Dependencies._();

  static final TokenStorage tokenStorage = TokenStorage();

  static final ApiClient apiClient = ApiClient(tokenStorage);

  static final AuthRepository authRepository = AuthRepository(
    apiClient,
    tokenStorage,
  );

  static final LoginController loginController = LoginController(
    authRepository,
  );
}
