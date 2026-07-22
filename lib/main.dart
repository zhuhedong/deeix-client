import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/app_config.dart';
import 'core/settings/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load prefs up front so the configured server URL is known before the first
  // network call (no flash to the default origin, no double Dio build).
  final prefs = await SharedPreferences.getInstance();
  final storedUrl = prefs.getString(kServerBaseUrlKey);
  final initialUrl = (storedUrl != null && storedUrl.trim().isNotEmpty)
      ? storedUrl
      : AppConfig.apiBaseUrl;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => prefs),
        serverInitialUrlProvider.overrideWithValue(initialUrl),
      ],
      child: const DeeixApp(),
    ),
  );
}
