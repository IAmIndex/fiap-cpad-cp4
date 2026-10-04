import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryPreferences extends Fake implements SharedPreferencesAsync {
  final _values = <String, String>{};

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;
}

void main() {
  test('theme preference survives a new controller', () async {
    final preferences = _MemoryPreferences();
    final original = ThemeController(preferences: preferences);
    await original.load();
    expect(original.mode, ThemeMode.system);
    await original.setMode(ThemeMode.dark);
    final restored = ThemeController(preferences: preferences);
    await restored.load();
    expect(restored.mode, ThemeMode.dark);
    await restored.setMode(ThemeMode.light);
    expect(await preferences.getString(ThemeController.preferenceKey), 'light');
    original.dispose();
    restored.dispose();
  });

  test('unknown theme preferences fall back to system', () async {
    final preferences = _MemoryPreferences();
    await preferences.setString(ThemeController.preferenceKey, 'invalid');
    final controller = ThemeController(preferences: preferences);
    await controller.load();
    expect(controller.mode, ThemeMode.system);
    controller.dispose();
  });
}
