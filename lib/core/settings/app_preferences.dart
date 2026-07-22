import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_config.dart';

const _themeModeKey = 'deeix_theme_mode';
const _defaultModelKey = 'deeix_default_model';
const _localeKey = 'deeix_locale';
const _fontScaleKey = 'deeix_font_scale';
const _genTempKey = 'deeix_gen_temperature';
const _genMaxTokensKey = 'deeix_gen_max_tokens';
const _sendEnterKey = 'deeix_send_with_enter';
const _bubbleStyleKey = 'deeix_bubble_style';

/// Persisted API origin (read in `main()` before the app boots).
const kServerBaseUrlKey = 'deeix_server_base_url';

class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  ThemeMode get themeMode {
    switch (_prefs.getString(_themeModeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_themeModeKey, value);
  }

  String? get defaultModel => _prefs.getString(_defaultModelKey);

  Future<void> setDefaultModel(String? model) async {
    if (model == null || model.isEmpty) {
      await _prefs.remove(_defaultModelKey);
    } else {
      await _prefs.setString(_defaultModelKey, model);
    }
  }

  /// `zh` | `en` | null (system)
  String? get localeCode => _prefs.getString(_localeKey);

  Future<void> setLocaleCode(String? code) async {
    if (code == null || code.isEmpty) {
      await _prefs.remove(_localeKey);
    } else {
      await _prefs.setString(_localeKey, code);
    }
  }

  double get fontScale => _prefs.getDouble(_fontScaleKey) ?? 1.0;

  Future<void> setFontScale(double scale) async {
    await _prefs.setDouble(_fontScaleKey, scale.clamp(0.85, 1.4));
  }

  double? get generationTemperature => _prefs.getDouble(_genTempKey);

  Future<void> setGenerationTemperature(double? v) async {
    if (v == null) {
      await _prefs.remove(_genTempKey);
    } else {
      await _prefs.setDouble(_genTempKey, v);
    }
  }

  int? get generationMaxTokens {
    final v = _prefs.getInt(_genMaxTokensKey);
    return v;
  }

  Future<void> setGenerationMaxTokens(int? v) async {
    if (v == null) {
      await _prefs.remove(_genMaxTokensKey);
    } else {
      await _prefs.setInt(_genMaxTokensKey, v);
    }
  }

  /// Enter key sends message (true) vs inserts newline (false). Default true.
  bool get sendWithEnter => _prefs.getBool(_sendEnterKey) ?? true;

  Future<void> setSendWithEnter(bool v) async {
    await _prefs.setBool(_sendEnterKey, v);
  }

  /// `comfortable` | `compact`
  String get bubbleStyle => _prefs.getString(_bubbleStyleKey) ?? 'comfortable';

  Future<void> setBubbleStyle(String style) async {
    await _prefs.setString(
      _bubbleStyleKey,
      style == 'compact' ? 'compact' : 'comfortable',
    );
  }

  /// User-configured API origin (no trailing slash, no `/api/v1`). Null → the
  /// build-time [AppConfig.apiBaseUrl] default.
  String? get serverBaseUrl => _prefs.getString(kServerBaseUrlKey);

  Future<void> setServerBaseUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _prefs.remove(kServerBaseUrlKey);
    } else {
      await _prefs.setString(kServerBaseUrlKey, url);
    }
  }

  Future<void> clearLocalPrefs() async {
    // Keep nothing app-local except we wipe all keys we own.
    await _prefs.remove(_themeModeKey);
    await _prefs.remove(_defaultModelKey);
    await _prefs.remove(_localeKey);
    await _prefs.remove(_fontScaleKey);
    await _prefs.remove(_genTempKey);
    await _prefs.remove(_genMaxTokensKey);
    await _prefs.remove(_sendEnterKey);
    await _prefs.remove(_bubbleStyleKey);
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final appPreferencesProvider = FutureProvider<AppPreferences>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AppPreferences(prefs);
});

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    Future.microtask(_load);
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    state = prefs.themeMode;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setThemeMode(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class DefaultModelController extends Notifier<String?> {
  @override
  String? build() {
    Future.microtask(_load);
    return null;
  }

  Future<void> _load() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    state = prefs.defaultModel;
  }

  Future<void> setModel(String? model) async {
    state = model;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setDefaultModel(model);
  }
}

final defaultModelProvider = NotifierProvider<DefaultModelController, String?>(
  DefaultModelController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    Future.microtask(_load);
    return null;
  }

  Future<void> _load() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    final code = prefs.localeCode;
    state = code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setLocaleCode(locale?.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class FontScaleController extends Notifier<double> {
  @override
  double build() {
    Future.microtask(_load);
    return 1.0;
  }

  Future<void> _load() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    state = prefs.fontScale;
  }

  Future<void> setScale(double scale) async {
    state = scale.clamp(0.85, 1.4);
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setFontScale(state);
  }
}

final fontScaleProvider = NotifierProvider<FontScaleController, double>(
  FontScaleController.new,
);

class GenOptionsState {
  const GenOptionsState({this.temperature, this.maxTokens});
  final double? temperature;
  final int? maxTokens;

  Map<String, dynamic>? toOptionsMap() {
    final map = <String, dynamic>{};
    if (temperature != null) map['temperature'] = temperature;
    if (maxTokens != null) map['max_tokens'] = maxTokens;
    return map.isEmpty ? null : map;
  }
}

class GenOptionsController extends Notifier<GenOptionsState> {
  @override
  GenOptionsState build() {
    Future.microtask(_load);
    return const GenOptionsState();
  }

  Future<void> _load() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    state = GenOptionsState(
      temperature: prefs.generationTemperature,
      maxTokens: prefs.generationMaxTokens,
    );
  }

  Future<void> setTemperature(double? v) async {
    state = GenOptionsState(temperature: v, maxTokens: state.maxTokens);
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setGenerationTemperature(v);
  }

  Future<void> setMaxTokens(int? v) async {
    state = GenOptionsState(temperature: state.temperature, maxTokens: v);
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setGenerationMaxTokens(v);
  }
}

final genOptionsProvider =
    NotifierProvider<GenOptionsController, GenOptionsState>(
      GenOptionsController.new,
    );

class SendWithEnterController extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(_load);
    return true;
  }

  Future<void> _load() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    state = prefs.sendWithEnter;
  }

  Future<void> setEnabled(bool v) async {
    state = v;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setSendWithEnter(v);
  }
}

final sendWithEnterProvider = NotifierProvider<SendWithEnterController, bool>(
  SendWithEnterController.new,
);

class BubbleStyleController extends Notifier<String> {
  @override
  String build() {
    Future.microtask(_load);
    return 'comfortable';
  }

  Future<void> _load() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    state = prefs.bubbleStyle;
  }

  Future<void> setStyle(String style) async {
    state = style == 'compact' ? 'compact' : 'comfortable';
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setBubbleStyle(state);
  }
}

final bubbleStyleProvider = NotifierProvider<BubbleStyleController, String>(
  BubbleStyleController.new,
);

/// Normalize a user-entered server address: ensure a scheme, drop trailing
/// slashes, and strip an accidental `/api/v1` suffix (the app adds that itself).
String normalizeServerUrl(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return '';
  if (!s.startsWith('http://') && !s.startsWith('https://')) {
    s = 'https://$s';
  }
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.toLowerCase().endsWith('/api/v1')) {
    s = s.substring(0, s.length - '/api/v1'.length);
  }
  return s;
}

/// Overridden in `main()` with the persisted server URL so networking starts on
/// the right origin without a first-frame flash to the default.
final serverInitialUrlProvider = Provider<String>(
  (ref) => AppConfig.apiBaseUrl,
);

class ServerUrlController extends Notifier<String> {
  @override
  String build() => ref.read(serverInitialUrlProvider);

  /// Persist a new API origin. Returns the normalized value applied, or '' if
  /// the input was invalid. Dio / auth-repository rebuild via their watchers.
  Future<String> setUrl(String raw) async {
    final url = normalizeServerUrl(raw);
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || uri.host.isEmpty) return '';
    if (url == state) return url;
    state = url;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setServerBaseUrl(url);
    return url;
  }

  Future<void> resetToDefault() async {
    state = AppConfig.apiBaseUrl;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setServerBaseUrl(null);
  }
}

final serverBaseUrlProvider = NotifierProvider<ServerUrlController, String>(
  ServerUrlController.new,
);
