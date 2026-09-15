import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/app_user.dart';

/// Every SharedPreferences key the app uses, in one place.
class AppPrefs {
  final SharedPreferences _prefs;

  AppPrefs(this._prefs);

  static const _loggedIn = 'logged_in';
  static const _user = 'user';
  static const _token = 'session_token';
  static const _theme = 'theme';
  static const _language = 'language';
  static const _lastSyncAt = 'last_sync_at';
  static const _activeCount = 'active_count_uuid';
  static const _offlineBannerDismissed = 'offline_banner_dismissed';
  static const _deviceId = 'device_id';

  bool get isLoggedIn => _prefs.getBool(_loggedIn) ?? false;

  AppUser? get user {
    final raw = _prefs.getString(_user);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  String? get token => _prefs.getString(_token);

  Future<void> saveSession(AppUser user, String token) async {
    await _prefs.setString(_user, jsonEncode(user.toJson()));
    await _prefs.setString(_token, token);
    await _prefs.setBool(_loggedIn, true);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_user);
    await _prefs.remove(_token);
    await _prefs.remove(_lastSyncAt);
    await _prefs.setBool(_loggedIn, false);
  }

  String? get theme => _prefs.getString(_theme);
  Future<void> setTheme(String value) => _prefs.setString(_theme, value);

  String? get language => _prefs.getString(_language);
  Future<void> setLanguage(String value) => _prefs.setString(_language, value);

  /// Server clock value from the last successful pull, as an ISO string.
  String? get lastSyncAt => _prefs.getString(_lastSyncAt);
  Future<void> setLastSyncAt(String value) => _prefs.setString(_lastSyncAt, value);

  String? get activeCountUuid => _prefs.getString(_activeCount);
  Future<void> setActiveCountUuid(String? value) =>
      value == null ? _prefs.remove(_activeCount) : _prefs.setString(_activeCount, value);

  bool get offlineBannerDismissed => _prefs.getBool(_offlineBannerDismissed) ?? false;
  Future<void> setOfflineBannerDismissed(bool value) =>
      _prefs.setBool(_offlineBannerDismissed, value);

  String? get deviceId => _prefs.getString(_deviceId);
  Future<void> setDeviceId(String value) => _prefs.setString(_deviceId, value);

  Future<void> reload() => _prefs.reload();
}
