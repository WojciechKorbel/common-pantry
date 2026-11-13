import 'package:common_pantry/app.dart';
import 'package:common_pantry/core/di/dependencies.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'env');
  await Dependencies.initAsync();

  runApp(const ProviderScope(child: App()));
}
