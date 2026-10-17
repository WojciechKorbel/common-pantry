import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/core/storage/token_storage.dart';
import 'package:common_pantry/features/auth/data/controllers/login_controller.dart';
import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/presentation/household_controller.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/pantry_controller.dart';

class Dependencies {
  Dependencies._();

  static final TokenStorage tokenStorage = TokenStorage();

  static final ApiClient apiClient = ApiClient(tokenStorage);

  // auth
  static final AuthRepository authRepository = AuthRepository(
    apiClient,
    tokenStorage,
  );

  static final LoginController loginController = LoginController(
    authRepository,
  );

  // household feature
  static final householdController = HouseholdController(
    initial: const Household(id: 1, name: 'Test pantry'),
  );

  // pantry feature
  static final pantryRepository = PantryRepository(apiClient);
  static final pantryController = PantryController(pantryRepository, householdController);
}
