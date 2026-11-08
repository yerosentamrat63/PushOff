# Push-Up Off: Antigravity Prompts

Run these in order. Check each step works before moving on. Start a fresh chat for each one.

## 1. Project setup and theme

```
Create a Flutter app "pushup_off" (Android + iOS), clean architecture with feature folders, Riverpod for state, go_router for navigation.
Build the theme from this design system (dark only):
bg #0F1113, surface #181B1E, border #262A2E, text #F2F4F1, muted #9BA3A8, accent lime #D4FF3A (text on accent #0F1500), warning #FF9466.
Fonts via google_fonts: Barlow Condensed (700, big numbers/headings, uppercase buttons) and Barlow (body).
Radii: cards 18-24, buttons 16-20. Primary button is lime, 56-64px tall.
Create shared widgets: PrimaryButton, SecondaryButton, AppCard, ProgressBar, StatTile, RankRow, BottomNav (Home, Groups, Board, Profile).
Set up routes for: login, onboarding, home, setup, countdown, live, summary, groups, groupDetail, createGroup, leaderboard, profile, settings. Use placeholder pages for now. The design screens are in the attached design files, match them.
```

## 2. Build all screens with mock data

```
Build every screen UI to match the attached design exactly, using hardcoded mock data and the shared widgets. Screens: Login, Onboarding, Home, Setup, Countdown, Live workout, Set summary, Groups, Group detail, Create group, Leaderboard (week/month/all-time tabs and group filter chips), Profile (stats, 7-day bar chart, recent sessions), Settings (toggles). Wire up all navigation. No camera or backend yet.
```

## 3. Camera and pose detection

```
Add the camera package and google_mlkit_pose_detection. On the Live screen, show the camera preview (prefer the front camera, portrait) and draw a skeleton overlay with a CustomPainter using the 33 landmarks, lime lines and joints. Run detection on a stream with frame throttling and an isolate if needed. Handle camera permission (Onboarding "Allow camera" button) and the denied state. On the Setup screen, show real checks: shoulders, elbows, wrists, hips, ankles visible with landmark confidence above 0.6.
```

## 4. Rep counting engine (most important step)

```
Create a pure Dart RepCounter class in features/workout/domain, with no Flutter imports, and unit tests.
Input: a stream of pose frames (landmarks with confidence). Output: state (UP/DOWN), valid reps, rejected reps with a reason, live elbow angle, body-line angle, and form score.
Rules:
- Angles: elbow = shoulder-elbow-wrist, body line = shoulder-hip-ankle. Use the side of the body with the higher confidence.
- Smooth angles with a moving average, and use hysteresis (enter DOWN below 100°, leave DOWN above 120°; enter UP above 155°).
- State machine UP -> DOWN -> UP. A rep is valid only if: elbow reached 90° or less at the bottom, full lockout (155° or more) at the top, body line stayed 165° or more the whole rep, and the rep took at least 0.4s.
- Otherwise reject it with a reason: not deep enough, hips sagging, hips piked, no lockout, too fast.
- Pause tracking when key landmarks drop below the confidence threshold.
Write unit tests with synthetic angle sequences covering valid reps, half reps, sagging hips and jitter. Make all thresholds constants in one config file.
```

## 5. Live workout, countdown and summary

```
Connect RepCounter to the Live screen: big valid rep count, rejected count, timer, live elbow/body-line/form tiles, and a warning banner showing the latest failure reason ("Go lower", "Keep hips up"). Add a 3-2-1 countdown on the Countdown screen that begins when all joints are detected. Add pause and end set. The Summary screen shows valid vs rejected, form score, time and the list of rejected reps with reasons. Add optional voice rep counting (flutter_tts) controlled by the Settings toggle.
```

## 6. Local storage

```
Add local persistence (Drift or Isar). Save sessions and sets (valid reps, rejected reps, form score, duration, timestamp, no video, ever). Drive Home (today's count, daily goal progress, streak), Profile (totals, best set, avg form, 7-day chart, recent sessions) and Settings (daily goal, camera, toggles) from real data.
```

## 7. Firebase auth and groups

```
Add Firebase Auth (email + Google) and Firestore. Design the schema: users, groups (name, goal, period, startsAt, endsAt, inviteCode, memberIds), groups/{id}/members (displayName, repsInPeriod), and sessions (userId, validReps, formScore, timestamp). Implement: sign up/login, create group (generate a unique invite code), join with code, group detail with live progress and member ranking, leaderboard by week/month/all-time and by group. After each set, upload only the counts to Firestore. Write Firestore security rules so users can only write their own data, and add a server-side cap on reps per minute (Cloud Function or rules) to block cheating.
```

## 8. Polish and testing

```
Add empty states (new user with no reps or groups), loading and error states, a haptic and short flash on a rejected rep, accessibility labels, and wake lock so the screen stays on during a set. Test on a real Android and iOS device in different lighting and with the phone at different distances, and list any thresholds that need tuning.
```

---

Step 4 decides whether the app feels good. Test it on a real phone before building the social side, and expect to tune the angle thresholds.
