import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyDailyGoal = 'pref_daily_goal';
  static const String _keyVoiceRepCount = 'pref_voice_rep_count';
  static const String _keyPreferFrontCamera = 'pref_prefer_front_camera';
  static const String _keyDailyReminder = 'pref_daily_reminder';
  static const String _keyGroupActivity = 'pref_group_activity';
  static const String _keyUserName = 'pref_user_name';
  static const String _keyHasSeenOnboarding = 'pref_has_seen_onboarding';
  static const String _keySignedIn = 'pref_signed_in';

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // In-memory fallback if platform channel unavailable
    }
  }

  int getDailyGoal() {
    return _prefs?.getInt(_keyDailyGoal) ??
        (_memoryCache[_keyDailyGoal] as int? ?? 100);
  }

  Future<void> setDailyGoal(int value) async {
    _memoryCache[_keyDailyGoal] = value;
    await _prefs?.setInt(_keyDailyGoal, value);
  }

  bool getVoiceRepCount() {
    return _prefs?.getBool(_keyVoiceRepCount) ??
        (_memoryCache[_keyVoiceRepCount] as bool? ?? true);
  }

  Future<void> setVoiceRepCount(bool value) async {
    _memoryCache[_keyVoiceRepCount] = value;
    await _prefs?.setBool(_keyVoiceRepCount, value);
  }

  bool getPreferFrontCamera() {
    return _prefs?.getBool(_keyPreferFrontCamera) ??
        (_memoryCache[_keyPreferFrontCamera] as bool? ?? true);
  }

  Future<void> setPreferFrontCamera(bool value) async {
    _memoryCache[_keyPreferFrontCamera] = value;
    await _prefs?.setBool(_keyPreferFrontCamera, value);
  }

  bool getDailyReminder() {
    return _prefs?.getBool(_keyDailyReminder) ??
        (_memoryCache[_keyDailyReminder] as bool? ?? true);
  }

  Future<void> setDailyReminder(bool value) async {
    _memoryCache[_keyDailyReminder] = value;
    await _prefs?.setBool(_keyDailyReminder, value);
  }

  bool getGroupActivity() {
    return _prefs?.getBool(_keyGroupActivity) ??
        (_memoryCache[_keyGroupActivity] as bool? ?? false);
  }

  Future<void> setGroupActivity(bool value) async {
    _memoryCache[_keyGroupActivity] = value;
    await _prefs?.setBool(_keyGroupActivity, value);
  }

  bool hasSeenOnboarding() {
    return _prefs?.getBool(_keyHasSeenOnboarding) ??
        (_memoryCache[_keyHasSeenOnboarding] as bool? ?? false);
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    _memoryCache[_keyHasSeenOnboarding] = value;
    await _prefs?.setBool(_keyHasSeenOnboarding, value);
  }

  bool isSignedIn() {
    return _prefs?.getBool(_keySignedIn) ??
        (_memoryCache[_keySignedIn] as bool? ?? false);
  }

  Future<void> setSignedIn(bool value) async {
    _memoryCache[_keySignedIn] = value;
    await _prefs?.setBool(_keySignedIn, value);
  }

  String getUserName() {
    return _prefs?.getString(_keyUserName) ??
        (_memoryCache[_keyUserName] as String? ?? 'Yerosen');
  }

  Future<void> setUserName(String value) async {
    _memoryCache[_keyUserName] = value;
    await _prefs?.setString(_keyUserName, value);
  }
}
