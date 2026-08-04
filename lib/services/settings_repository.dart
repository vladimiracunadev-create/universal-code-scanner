import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_code_scanner/core/feature_flags/feature_flags.dart';
import 'package:universal_code_scanner/models/app_settings.dart';

class SettingsRepository {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<AppSettings> load() async {
    final String themeName = await _preferences.getString('theme_mode') ?? 'system';
    final String languageName = await _preferences.getString('language') ?? 'system';
    final String? flagsJson = await _preferences.getString('feature_flags');
    FeatureFlags flags = const FeatureFlags();
    if (flagsJson != null) {
      try {
        flags = FeatureFlags.fromJson(Map<String, dynamic>.from(jsonDecode(flagsJson) as Map));
      } on Object {
        flags = const FeatureFlags();
      }
    }
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere((ThemeMode mode) => mode.name == themeName, orElse: () => ThemeMode.system),
      language: AppLanguage.values.firstWhere((AppLanguage item) => item.name == languageName, orElse: () => AppLanguage.system),
      soundEnabled: await _preferences.getBool('sound_enabled') ?? true,
      vibrationEnabled: await _preferences.getBool('vibration_enabled') ?? true,
      saveHistory: await _preferences.getBool('save_history') ?? true,
      privateMode: await _preferences.getBool('private_mode') ?? false,
      autoTorch: await _preferences.getBool('auto_torch') ?? false,
      useScanWindow: await _preferences.getBool('use_scan_window') ?? true,
      confirmBeforeOpen: await _preferences.getBool('confirm_before_open') ?? true,
      hideSensitiveValues: await _preferences.getBool('hide_sensitive_values') ?? true,
      biometricLock: await _preferences.getBool('biometric_lock') ?? false,
      highContrast: await _preferences.getBool('high_contrast') ?? false,
      largeControls: await _preferences.getBool('large_controls') ?? false,
      reduceMotion: await _preferences.getBool('reduce_motion') ?? false,
      clearClipboardSeconds: await _preferences.getInt('clear_clipboard_seconds') ?? 30,
      historyRetentionDays: await _preferences.getInt('history_retention_days') ?? 0,
      featureFlags: flags,
    );
  }

  Future<void> save(AppSettings value) async {
    await Future.wait(<Future<void>>[
      _preferences.setString('theme_mode', value.themeMode.name),
      _preferences.setString('language', value.language.name),
      _preferences.setBool('sound_enabled', value.soundEnabled),
      _preferences.setBool('vibration_enabled', value.vibrationEnabled),
      _preferences.setBool('save_history', value.saveHistory),
      _preferences.setBool('private_mode', value.privateMode),
      _preferences.setBool('auto_torch', value.autoTorch),
      _preferences.setBool('use_scan_window', value.useScanWindow),
      _preferences.setBool('confirm_before_open', value.confirmBeforeOpen),
      _preferences.setBool('hide_sensitive_values', value.hideSensitiveValues),
      _preferences.setBool('biometric_lock', value.biometricLock),
      _preferences.setBool('high_contrast', value.highContrast),
      _preferences.setBool('large_controls', value.largeControls),
      _preferences.setBool('reduce_motion', value.reduceMotion),
      _preferences.setInt('clear_clipboard_seconds', value.clearClipboardSeconds),
      _preferences.setInt('history_retention_days', value.historyRetentionDays),
      _preferences.setString('feature_flags', jsonEncode(value.featureFlags.toJson())),
    ]);
  }

  Future<void> resetNonSensitive() async {
    const List<String> keys = <String>[
      'theme_mode', 'language', 'sound_enabled', 'vibration_enabled', 'auto_torch',
      'use_scan_window', 'confirm_before_open', 'hide_sensitive_values', 'high_contrast',
      'large_controls', 'reduce_motion', 'clear_clipboard_seconds', 'history_retention_days',
      'feature_flags',
    ];
    for (final String key in keys) {
      await _preferences.remove(key);
    }
  }
}
