import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pushup_off/core/theme/app_colors.dart';
import 'package:pushup_off/core/theme/app_theme.dart';
import 'package:pushup_off/core/widgets/primary_button.dart';
import 'package:pushup_off/core/widgets/secondary_button.dart';
import 'package:pushup_off/core/widgets/app_card.dart';
import 'package:pushup_off/core/widgets/progress_bar.dart';
import 'package:pushup_off/core/widgets/stat_tile.dart';
import 'package:pushup_off/core/widgets/rank_row.dart';
import 'package:pushup_off/core/widgets/bottom_nav.dart';
import 'package:pushup_off/features/workout/presentation/set_summary_screen.dart';

void main() {
  testWidgets('Design System and Shared Widgets render properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Start set',
                    onPressed: () {},
                  ),
                  SecondaryButton(
                    label: 'Join',
                    onPressed: () {},
                  ),
                  const AppCard(
                    child: Text('Card Content'),
                  ),
                  const ProgressBar(value: 0.64),
                  const StatTile(
                    label: 'Valid push-ups',
                    value: '64',
                    secondaryValue: '/ 100',
                  ),
                  const RankRow(
                    rank: 1,
                    name: 'Dawit',
                    reps: 118,
                  ),
                  BottomNav(
                    currentTab: NavTab.home,
                    onSelectTab: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('START SET'), findsOneWidget);
    expect(find.text('JOIN'), findsOneWidget);
    expect(find.text('Card Content'), findsOneWidget);
    expect(find.text('64'), findsWidgets);
    expect(find.text('Dawit'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('SetSummaryScreen renders valid breakdown and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SetSummaryScreen(),
        ),
      ),
    );

    expect(find.text('Nice set'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('SAVE AND FINISH'), findsOneWidget);
    expect(find.text('ANOTHER SET'), findsOneWidget);
  });
}
