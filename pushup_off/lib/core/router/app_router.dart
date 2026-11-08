import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_paths.dart';
import '../widgets/main_scaffold.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/workout/presentation/setup_screen.dart';
import '../../features/workout/presentation/countdown_screen.dart';
import '../../features/workout/presentation/live_workout_screen.dart';
import '../../features/workout/presentation/set_summary_screen.dart';
import '../../features/groups/presentation/groups_screen.dart';
import '../../features/groups/presentation/group_detail_screen.dart';
import '../../features/groups/presentation/create_group_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/settings_controller.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  // First launch opens login, then onboarding, then home. Returning users who
  // are signed in skip straight to home.
  final preferences = ref.watch(preferencesServiceProvider);
  final initialLocation = !preferences.isSignedIn()
      ? RoutePaths.login
      : (!preferences.hasSeenOnboarding()
          ? RoutePaths.onboarding
          : RoutePaths.home);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      // Auth & Onboarding (Full Screen)
      GoRoute(
        path: RoutePaths.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Tab Shell Routes with persistent Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(
            location: state.uri.toString(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: RoutePaths.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.groups,
            name: 'groups',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GroupsScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.leaderboard,
            name: 'leaderboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LeaderboardScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.profile,
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Workout Flow Routes (Full Screen with rootNavigatorKey)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.setup,
        name: 'setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.countdown,
        name: 'countdown',
        builder: (context, state) => const CountdownScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.live,
        name: 'live',
        builder: (context, state) => const LiveWorkoutScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.summary,
        name: 'summary',
        builder: (context, state) => const SetSummaryScreen(),
      ),

      // Group Sub-Routes
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.groupDetailPath,
        name: 'groupDetail',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? 'gym-rats';
          return GroupDetailScreen(groupId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.createGroup,
        name: 'createGroup',
        builder: (context, state) => const CreateGroupScreen(),
      ),

      // Settings
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
