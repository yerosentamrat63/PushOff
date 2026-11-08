import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/route_paths.dart';
import 'bottom_nav.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final String location;

  const MainScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  NavTab _getTabFromLocation(String loc) {
    if (loc.startsWith(RoutePaths.groups)) return NavTab.groups;
    if (loc.startsWith(RoutePaths.leaderboard)) return NavTab.board;
    if (loc.startsWith(RoutePaths.profile)) return NavTab.profile;
    return NavTab.home;
  }

  void _onSelectTab(BuildContext context, NavTab tab) {
    switch (tab) {
      case NavTab.home:
        context.go(RoutePaths.home);
        break;
      case NavTab.groups:
        context.go(RoutePaths.groups);
        break;
      case NavTab.board:
        context.go(RoutePaths.leaderboard);
        break;
      case NavTab.profile:
        context.go(RoutePaths.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _getTabFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNav(
        currentTab: currentTab,
        onSelectTab: (tab) => _onSelectTab(context, tab),
      ),
    );
  }
}

