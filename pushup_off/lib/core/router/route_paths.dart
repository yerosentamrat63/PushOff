abstract final class RoutePaths {
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  
  // Tab routes
  static const String home = '/home';
  static const String groups = '/groups';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';

  // Workout flow routes
  static const String setup = '/setup';
  static const String countdown = '/countdown';
  static const String live = '/live';
  static const String summary = '/summary';

  // Group sub-routes
  static const String groupDetailPath = '/group-detail';
  static String groupDetail([String? id]) => id != null ? '/group-detail?id=$id' : '/group-detail';
  static const String createGroup = '/create-group';

  // Settings
  static const String settings = '/settings';
}

