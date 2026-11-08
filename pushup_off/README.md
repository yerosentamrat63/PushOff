# Push-Up Off (Flutter App)

AI-powered push-up tracking, competitive workouts, and group leaderboards.

## Tech Stack
- **Framework:** Flutter (Android + iOS)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Navigation:** `go_router` with ShellRoute for bottom navigation and dedicated full-screen modals
- **Typography:** `google_fonts` (`Barlow Condensed 700` for headings/stats/buttons, `Barlow` for body)
- **Design System:** Pure dark mode (#0F1113 background, #181B1E surface, #D4FF3A accent lime, #FF9466 warning)

## Architecture Overview
```
pushup_off/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   └── route_paths.dart
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   └── app_theme.dart
│   │   └── widgets/
│   │       ├── app_card.dart
│   │       ├── app_header.dart
│   │       ├── bottom_nav.dart
│   │       ├── main_scaffold.dart
│   │       ├── primary_button.dart
│   │       ├── progress_bar.dart
│   │       ├── rank_row.dart
│   │       ├── secondary_button.dart
│   │       └── stat_tile.dart
│   └── features/
│       ├── auth/presentation/login_screen.dart
│       ├── onboarding/presentation/onboarding_screen.dart
│       ├── home/presentation/home_screen.dart
│       ├── workout/presentation/
│       │   ├── setup_screen.dart
│       │   ├── countdown_screen.dart
│       │   ├── live_workout_screen.dart
│       │   └── set_summary_screen.dart
│       ├── groups/presentation/
│       │   ├── groups_screen.dart
│       │   ├── group_detail_screen.dart
│       │   └── create_group_screen.dart
│       ├── leaderboard/presentation/leaderboard_screen.dart
│       ├── profile/presentation/profile_screen.dart
│       └── settings/presentation/settings_screen.dart
└── test/
    └── widget_test.dart
```

## Routes
- `/login` - Login with Google / Email
- `/onboarding` - Camera permission & pose tracking intro
- `/home` - Daily progress, streak, start workout, active squads
- `/setup` - Camera angle positioning & landmark detection check
- `/countdown` - 3-2-1 countdown sequence
- `/live` - Real-time camera HUD, angle trackers, warning alerts, rep counters
- `/summary` - Set breakdown, valid vs rejected reps, failure reasons
- `/groups` - Active group challenges & invite code entry
- `/group-detail` - Squad progress, member leaderboard, invite code share
- `/create-group` - Group challenge creation
- `/leaderboard` - Week/Month/All-time podium rankings and filter chips
- `/profile` - Totals, best set, 7-day bar chart, recent sessions
- `/settings` - Voice counting, haptic toggle, wake lock, daily target

