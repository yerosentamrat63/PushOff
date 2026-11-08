import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/preferences_service.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final service = PreferencesService();
  service.init();
  return service;
});

final voiceRepCountEnabledProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final initial = prefs.getVoiceRepCount();
  ref.listenSelf((prev, next) {
    prefs.setVoiceRepCount(next);
  });
  return initial;
});

final preferFrontCameraProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final initial = prefs.getPreferFrontCamera();
  ref.listenSelf((prev, next) {
    prefs.setPreferFrontCamera(next);
  });
  return initial;
});

final dailyGoalRepsProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final initial = prefs.getDailyGoal();
  ref.listenSelf((prev, next) {
    prefs.setDailyGoal(next);
  });
  return initial;
});

final dailyReminderEnabledProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final initial = prefs.getDailyReminder();
  ref.listenSelf((prev, next) {
    prefs.setDailyReminder(next);
  });
  return initial;
});

final groupActivityEnabledProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final initial = prefs.getGroupActivity();
  ref.listenSelf((prev, next) {
    prefs.setGroupActivity(next);
  });
  return initial;
});
