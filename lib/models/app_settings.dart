import 'package:flutter/material.dart';
import 'package:universal_code_scanner/core/feature_flags/feature_flags.dart';

enum AppLanguage { system, esCl, es, en }

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.system,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.saveHistory = true,
    this.privateMode = false,
    this.autoTorch = false,
    this.useScanWindow = true,
    this.confirmBeforeOpen = true,
    this.hideSensitiveValues = true,
    this.biometricLock = false,
    this.highContrast = false,
    this.largeControls = false,
    this.reduceMotion = false,
    this.clearClipboardSeconds = 30,
    this.historyRetentionDays = 0,
    this.featureFlags = const FeatureFlags(),
  });

  final ThemeMode themeMode;
  final AppLanguage language;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool saveHistory;
  final bool privateMode;
  final bool autoTorch;
  final bool useScanWindow;
  final bool confirmBeforeOpen;
  final bool hideSensitiveValues;
  final bool biometricLock;
  final bool highContrast;
  final bool largeControls;
  final bool reduceMotion;
  final int clearClipboardSeconds;
  final int historyRetentionDays;
  final FeatureFlags featureFlags;

  Locale? get locale => switch (language) {
        AppLanguage.system => null,
        AppLanguage.esCl => const Locale('es', 'CL'),
        AppLanguage.es => const Locale('es'),
        AppLanguage.en => const Locale('en'),
      };

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? saveHistory,
    bool? privateMode,
    bool? autoTorch,
    bool? useScanWindow,
    bool? confirmBeforeOpen,
    bool? hideSensitiveValues,
    bool? biometricLock,
    bool? highContrast,
    bool? largeControls,
    bool? reduceMotion,
    int? clearClipboardSeconds,
    int? historyRetentionDays,
    FeatureFlags? featureFlags,
  }) => AppSettings(
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        saveHistory: saveHistory ?? this.saveHistory,
        privateMode: privateMode ?? this.privateMode,
        autoTorch: autoTorch ?? this.autoTorch,
        useScanWindow: useScanWindow ?? this.useScanWindow,
        confirmBeforeOpen: confirmBeforeOpen ?? this.confirmBeforeOpen,
        hideSensitiveValues: hideSensitiveValues ?? this.hideSensitiveValues,
        biometricLock: biometricLock ?? this.biometricLock,
        highContrast: highContrast ?? this.highContrast,
        largeControls: largeControls ?? this.largeControls,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        clearClipboardSeconds: clearClipboardSeconds ?? this.clearClipboardSeconds,
        historyRetentionDays: historyRetentionDays ?? this.historyRetentionDays,
        featureFlags: featureFlags ?? this.featureFlags,
      );
}
