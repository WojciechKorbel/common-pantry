import 'package:common_pantry/core/network/api_client.dart';
import 'package:common_pantry/core/storage/token_storage.dart';
import 'package:common_pantry/features/auth/data/repositories/auth_repository.dart';
import 'package:common_pantry/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:common_pantry/features/auth/presentation/controllers/login_controller.dart';
import 'package:common_pantry/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:common_pantry/features/auth/presentation/controllers/sign_up_controller.dart';
import 'package:common_pantry/features/auth/presentation/controllers/verify_email_controller.dart';
import 'package:common_pantry/features/auth/presentation/controllers/verify_reset_code_controller.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/households/data/repositories/household_repository.dart';
import 'package:common_pantry/features/households/presentation/controllers/create_household_controller.dart';
import 'package:common_pantry/features/households/presentation/controllers/household_controller.dart';
import 'package:common_pantry/features/households/presentation/controllers/join_household_controller.dart';
import 'package:common_pantry/features/pantry/data/repositories/pantry_repository.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/household_details_controller.dart';
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

  static final signUpController = SignUpController(
    authRepository,
  );

  static final verifyEmailController = VerifyEmailController(
    authRepository,
  );

  // password reset
  static final forgotPasswordController = ForgotPasswordController(authRepository);

  static final verifyResetCodeController = VerifyResetCodeController(authRepository);

  static final resetPasswordController = ResetPasswordController(authRepository);

  // household feature
  static final householdsRepository = HouseholdsRepository(apiClient);

  static final createHouseholdController = CreateHouseholdController(
    householdsRepository,
  );

  static final joinHouseholdController = JoinHouseholdController(
    householdsRepository,
  );

  static final householdController = HouseholdController(
    repository: householdsRepository,
    initial: const Household(id: 1, name: 'Test pantry'),
  );

  // pantry feature
  static final pantryRepository = PantryRepository(apiClient);
  static final pantryController = PantryController(pantryRepository, householdController);

  static HouseholdDetailsController householdDetailsController(
    int householdId,
  ) {
    return HouseholdDetailsController(
      repository: pantryRepository,
      householdId: householdId,
    );
  }
}
