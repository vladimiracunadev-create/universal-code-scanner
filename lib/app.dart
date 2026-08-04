import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:universal_code_scanner/core/localization/app_localizations.dart';
import 'package:universal_code_scanner/core/recovery/recovery_repository.dart';
import 'package:universal_code_scanner/core/recovery/recovery_service.dart';
import 'package:universal_code_scanner/core/theme/app_theme.dart';
import 'package:universal_code_scanner/core/security/data_maintenance_service.dart';
import 'package:universal_code_scanner/features/generator/generator_screen.dart';
import 'package:universal_code_scanner/features/history/history_screen.dart';
import 'package:universal_code_scanner/features/inventory/inventory_screen.dart';
import 'package:universal_code_scanner/features/scanner/scanner_screen.dart';
import 'package:universal_code_scanner/features/settings/settings_screen.dart';
import 'package:universal_code_scanner/services/biometric_service.dart';
import 'package:universal_code_scanner/state/inventory_store.dart';
import 'package:universal_code_scanner/state/scan_store.dart';
import 'package:universal_code_scanner/state/settings_store.dart';

class UniversalCodeScannerApp extends StatelessWidget {
  const UniversalCodeScannerApp({
    required this.scanStore,
    required this.inventoryStore,
    required this.settingsStore,
    required this.recoveryRepository,
    required this.recoveryService,
    required this.dataMaintenanceService,
    required this.temporaryMode,
    super.key,
  });

  final ScanStore scanStore;
  final InventoryStore inventoryStore;
  final SettingsStore settingsStore;
  final RecoveryRepository recoveryRepository;
  final RecoveryService recoveryService;
  final DataMaintenanceService dataMaintenanceService;
  final bool temporaryMode;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsStore,
      builder: (BuildContext context, Widget? child) {
        final settings = settingsStore.value;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Universal Code Scanner',
          theme: AppTheme.light(
            highContrast: settings.highContrast,
            largeControls: settings.largeControls,
            reduceMotion: settings.reduceMotion,
          ),
          darkTheme: AppTheme.dark(
            highContrast: settings.highContrast,
            largeControls: settings.largeControls,
            reduceMotion: settings.reduceMotion,
          ),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HandheldFrame(
            child: BiometricLockGate(
              settings: settingsStore,
              child: HomeShell(
                scanStore: scanStore,
                inventoryStore: inventoryStore,
                settingsStore: settingsStore,
                recoveryRepository: recoveryRepository,
                recoveryService: recoveryService,
                dataMaintenanceService: dataMaintenanceService,
                temporaryMode: temporaryMode,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Keeps the interface at a handheld width on large screens.
///
/// The layout is designed for a phone. On a desktop browser or a tablet it
/// would otherwise stretch edge to edge, leaving the reading frame and the
/// navigation bar absurdly wide. Below the threshold nothing is wrapped, so
/// phones keep the exact same tree.
class HandheldFrame extends StatelessWidget {
  const HandheldFrame({required this.child, super.key});

  static const double maxWidth = 560;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        final ColorScheme colors = Theme.of(context).colorScheme;
        return ColoredBox(
          color: colors.surfaceContainerHighest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: Material(color: colors.surface, child: child),
            ),
          ),
        );
      },
    );
  }
}

class BiometricLockGate extends StatefulWidget {
  const BiometricLockGate({required this.settings, required this.child, super.key});
  final SettingsStore settings;
  final Widget child;

  @override
  State<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends State<BiometricLockGate> with WidgetsBindingObserver {
  final BiometricService _biometric = BiometricService();
  bool _unlocked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlocked = !widget.settings.value.biometricLock;
    if (!_unlocked) WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_unlock()));
  }

  @override
  void didUpdateWidget(covariant BiometricLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.settings.value.biometricLock) _unlocked = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (widget.settings.value.biometricLock && mounted) setState(() => _unlocked = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked || !widget.settings.value.biometricLock) return widget.child;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lock_outline, size: 72, semanticLabel: 'Aplicación bloqueada'),
              const SizedBox(height: 18),
              Text('Aplicación protegida', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Autentícate con el método de seguridad configurado en el dispositivo.', textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _authenticating ? null : _unlock,
                icon: _authenticating
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.fingerprint),
                label: const Text('Desbloquear'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final bool result = await _biometric.authenticate();
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      _unlocked = result;
    });
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.scanStore,
    required this.inventoryStore,
    required this.settingsStore,
    required this.recoveryRepository,
    required this.recoveryService,
    required this.dataMaintenanceService,
    required this.temporaryMode,
    super.key,
  });

  final ScanStore scanStore;
  final InventoryStore inventoryStore;
  final SettingsStore settingsStore;
  final RecoveryRepository recoveryRepository;
  final RecoveryService recoveryService;
  final DataMaintenanceService dataMaintenanceService;
  final bool temporaryMode;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = <Widget>[
      ScannerScreen(store: widget.scanStore, settings: widget.settingsStore),
      InventoryScreen(store: widget.inventoryStore, settings: widget.settingsStore),
      GeneratorScreen(settings: widget.settingsStore),
      HistoryScreen(store: widget.scanStore, settings: widget.settingsStore),
      SettingsScreen(
        settings: widget.settingsStore,
        scanStore: widget.scanStore,
        recoveryRepository: widget.recoveryRepository,
        recoveryService: widget.recoveryService,
        dataMaintenanceService: widget.dataMaintenanceService,
        temporaryMode: widget.temporaryMode,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (widget.temporaryMode)
              MaterialBanner(
                content: const Text('Modo temporal: el historial y los inventarios se eliminarán al cerrar la aplicación.'),
                leading: const Icon(Icons.visibility_off_outlined),
                actions: const <Widget>[SizedBox.shrink()],
              ),
            Expanded(child: screens[_index]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.qr_code_scanner_outlined), selectedIcon: const Icon(Icons.qr_code_scanner), label: context.strings.scan),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2), label: context.strings.inventory),
          NavigationDestination(icon: const Icon(Icons.qr_code_2_outlined), selectedIcon: const Icon(Icons.qr_code_2), label: context.strings.generate),
          NavigationDestination(icon: const Icon(Icons.history_outlined), selectedIcon: const Icon(Icons.history), label: context.strings.history),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: context.strings.settings),
        ],
      ),
    );
  }
}
