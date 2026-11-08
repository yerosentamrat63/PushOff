import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_database.dart';
import 'core/storage/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'features/workout/presentation/controllers/workout_history_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional in this checkout: until google-services.json /
  // GoogleService-Info.plist are added, the app runs on its local demo data.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase is not configured; continuing in local mode: $e');
  }

  // Preload storage so the first screen renders real (seeded) data instead of
  // racing a background database open.
  final preferencesService = PreferencesService();
  await preferencesService.init();

  final localDatabase = LocalDatabase();
  await localDatabase.init();

  // Dark system UI overlay styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF14171A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
        localDatabaseProvider.overrideWithValue(localDatabase),
      ],
      child: const PushUpOffApp(),
    ),
  );
}

class PushUpOffApp extends ConsumerWidget {
  const PushUpOffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Push-Up Off',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
