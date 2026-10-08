import 'package:shared_preferences/shared_preferences.dart';
import '../../../engine/game/puzzle_engine.dart';
import '../../theme/app_theme.dart';

class AppPreferences {
  static const _keyTheme = 'pref_theme_mode';
  static const _keyMistakePolicy = 'pref_mistake_policy';
  static const _keyHaptics = 'pref_haptics_enabled';
  static const _keyReducedMotion = 'pref_reduced_motion';
  static const _keyPrecisionInput = 'pref_precision_input';
  static const _keySound = 'pref_sound_enabled';
  static const _keyGridScale = 'pref_grid_scale';
  static const _keySeenTutorial = 'pref_seen_tutorial';

  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  static Future<AppPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(prefs);
  }

  NonogramThemeMode get themeMode {
    final val = _prefs.getString(_keyTheme);
    return val != null ? NonogramThemeMode.fromString(val) : NonogramThemeMode.classicPaper;
  }

  Future<void> setThemeMode(NonogramThemeMode mode) =>
      _prefs.setString(_keyTheme, mode.name);

  MistakePolicy get mistakePolicy {
    final val = _prefs.getString(_keyMistakePolicy);
    return val == 'strict' ? MistakePolicy.strict : MistakePolicy.relax;
  }

  Future<void> setMistakePolicy(MistakePolicy policy) =>
      _prefs.setString(_keyMistakePolicy, policy.name);

  bool get hapticsEnabled => _prefs.getBool(_keyHaptics) ?? true;

  Future<void> setHapticsEnabled(bool enabled) =>
      _prefs.setBool(_keyHaptics, enabled);

  bool get reducedMotion => _prefs.getBool(_keyReducedMotion) ?? false;

  Future<void> setReducedMotion(bool enabled) =>
      _prefs.setBool(_keyReducedMotion, enabled);

  bool get precisionInputEnabled => _prefs.getBool(_keyPrecisionInput) ?? false;

  Future<void> setPrecisionInputEnabled(bool enabled) =>
      _prefs.setBool(_keyPrecisionInput, enabled);

  bool get soundEnabled => _prefs.getBool(_keySound) ?? true;

  Future<void> setSoundEnabled(bool enabled) =>
      _prefs.setBool(_keySound, enabled);

  double get gridScale => _prefs.getDouble(_keyGridScale) ?? 1.0;

  Future<void> setGridScale(double scale) =>
      _prefs.setDouble(_keyGridScale, scale);

  bool get seenTutorial => _prefs.getBool(_keySeenTutorial) ?? false;

  Future<void> setSeenTutorial(bool seen) =>
      _prefs.setBool(_keySeenTutorial, seen);
}
