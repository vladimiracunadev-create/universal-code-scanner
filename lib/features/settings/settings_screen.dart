import 'dart:async';

import 'package:flutter/material.dart';
import 'package:universal_code_scanner/core/localization/app_localizations.dart';
import 'package:universal_code_scanner/core/recovery/recovery_repository.dart';
import 'package:universal_code_scanner/core/recovery/recovery_service.dart';
import 'package:universal_code_scanner/core/security/data_maintenance_service.dart';
import 'package:universal_code_scanner/features/formats/formats_screen.dart';
import 'package:universal_code_scanner/features/recovery/recovery_screen.dart';
import 'package:universal_code_scanner/models/app_settings.dart';
import 'package:universal_code_scanner/services/biometric_service.dart';
import 'package:universal_code_scanner/state/scan_store.dart';
import 'package:universal_code_scanner/state/settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settings,
    required this.scanStore,
    required this.recoveryRepository,
    required this.recoveryService,
    required this.dataMaintenanceService,
    required this.temporaryMode,
    super.key,
  });

  final SettingsStore settings;
  final ScanStore scanStore;
  final RecoveryRepository recoveryRepository;
  final RecoveryService recoveryService;
  final DataMaintenanceService dataMaintenanceService;
  final bool temporaryMode;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometric = BiometricService();
  bool _rotatingKey = false;

  AppSettings get value => widget.settings.value;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: <Widget>[
        Text(context.strings.settings, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _Section(
          title: 'Apariencia',
          children: <Widget>[
            SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment(value: ThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.settings_brightness)),
                ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode_outlined)),
              ],
              selected: <ThemeMode>{value.themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) => _update(value.copyWith(themeMode: selection.first)),
            ),
            ListTile(
              title: const Text('Idioma'),
              trailing: DropdownButton<AppLanguage>(
                // English is not offered in 1.0.0. A preference stored by a
                // future build must not leave the dropdown without a match.
                value: value.language == AppLanguage.en ? AppLanguage.system : value.language,
                items: const <DropdownMenuItem<AppLanguage>>[
                  DropdownMenuItem(value: AppLanguage.system, child: Text('Sistema')),
                  DropdownMenuItem(value: AppLanguage.esCl, child: Text('Español (Chile)')),
                  DropdownMenuItem(value: AppLanguage.es, child: Text('Español internacional')),
                ],
                onChanged: (AppLanguage? language) => language == null ? null : _update(value.copyWith(language: language)),
              ),
            ),
            SwitchListTile(
              title: const Text('Alto contraste'),
              value: value.highContrast,
              onChanged: (bool enabled) => _update(value.copyWith(highContrast: enabled)),
            ),
            SwitchListTile(
              title: const Text('Controles más grandes'),
              subtitle: const Text('Aumenta las superficies táctiles sin reducir el tamaño del texto del sistema.'),
              value: value.largeControls,
              onChanged: (bool enabled) => _update(value.copyWith(largeControls: enabled)),
            ),
            SwitchListTile(
              title: const Text('Reducir movimiento'),
              value: value.reduceMotion,
              onChanged: (bool enabled) => _update(value.copyWith(reduceMotion: enabled)),
            ),
          ],
        ),
        _Section(
          title: 'Escáner',
          children: <Widget>[
            SwitchListTile(
              title: const Text('Marco de lectura real'),
              subtitle: const Text('Limita la detección al rectángulo central en plataformas compatibles.'),
              value: value.useScanWindow,
              onChanged: (bool enabled) => _update(value.copyWith(useScanWindow: enabled)),
            ),
            SwitchListTile(
              title: const Text('Linterna al iniciar'),
              value: value.autoTorch,
              onChanged: (bool enabled) => _update(value.copyWith(autoTorch: enabled)),
            ),
            SwitchListTile(
              title: const Text('Sonido de confirmación'),
              value: value.soundEnabled,
              onChanged: (bool enabled) => _update(value.copyWith(soundEnabled: enabled)),
            ),
            SwitchListTile(
              title: const Text('Vibración'),
              value: value.vibrationEnabled,
              onChanged: (bool enabled) => _update(value.copyWith(vibrationEnabled: enabled)),
            ),
          ],
        ),
        _Section(
          title: 'Privacidad y seguridad',
          children: <Widget>[
            SwitchListTile(
              title: const Text('Guardar historial'),
              subtitle: const Text('Los registros se cifran antes de guardarse en la base local.'),
              value: value.saveHistory,
              onChanged: (bool enabled) => _update(value.copyWith(saveHistory: enabled)),
            ),
            SwitchListTile(
              title: const Text('Sesión privada'),
              subtitle: const Text('Mientras esté activa, ninguna lectura se guarda.'),
              value: value.privateMode,
              onChanged: (bool enabled) => _update(value.copyWith(privateMode: enabled)),
            ),
            SwitchListTile(
              title: const Text('Ocultar valores sensibles'),
              subtitle: const Text('Protege contraseñas Wi-Fi, secretos OTP, pagos e identificaciones.'),
              value: value.hideSensitiveValues,
              onChanged: (bool enabled) => _update(value.copyWith(hideSensitiveValues: enabled)),
            ),
            SwitchListTile(
              title: const Text('Confirmar antes de abrir'),
              value: value.confirmBeforeOpen,
              onChanged: (bool enabled) => _update(value.copyWith(confirmBeforeOpen: enabled)),
            ),
            SwitchListTile(
              title: const Text('Bloqueo de la aplicación'),
              subtitle: const Text('Usa huella, rostro, PIN, patrón o código cuando la plataforma lo permite.'),
              value: value.biometricLock,
              onChanged: _changeBiometricLock,
            ),
            ListTile(
              title: const Text('Borrar portapapeles'),
              subtitle: const Text('El contenido copiado se elimina automáticamente si no cambió.'),
              trailing: DropdownButton<int>(
                value: value.clearClipboardSeconds,
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem(value: 0, child: Text('Nunca')),
                  DropdownMenuItem(value: 15, child: Text('15 s')),
                  DropdownMenuItem(value: 30, child: Text('30 s')),
                  DropdownMenuItem(value: 60, child: Text('1 min')),
                  DropdownMenuItem(value: 300, child: Text('5 min')),
                ],
                onChanged: (int? seconds) => seconds == null ? null : _update(value.copyWith(clearClipboardSeconds: seconds)),
              ),
            ),
            ListTile(
              title: const Text('Retención del historial'),
              subtitle: const Text('Elimina automáticamente las lecturas más antiguas al iniciar o cambiar esta opción.'),
              trailing: DropdownButton<int>(
                value: value.historyRetentionDays,
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem(value: 0, child: Text('Sin límite')),
                  DropdownMenuItem(value: 30, child: Text('30 días')),
                  DropdownMenuItem(value: 90, child: Text('90 días')),
                  DropdownMenuItem(value: 365, child: Text('1 año')),
                ],
                onChanged: (int? days) => days == null ? null : unawaited(_updateRetention(days)),
              ),
            ),
          ],
        ),
        _Section(
          title: 'Datos y compatibilidad',
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.grid_view_outlined),
              title: const Text('Formatos compatibles'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: SafeArea(child: FormatsScreen())))),
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('Centro de recuperación'),
              subtitle: const Text('Revisa migraciones, registros dañados y diagnóstico privado.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => RecoveryScreen(
                  service: widget.recoveryService,
                  retryMigration: _retryMigration,
                ),
              )),
            ),
            if (widget.scanStore.migrationStatus?.completed == false)
              ListTile(
                leading: const Icon(Icons.sync_problem_outlined),
                title: const Text('Reintentar migración del historial'),
                subtitle: Text(widget.scanStore.migrationStatus?.errorCode ?? 'La fuente anterior se conserva intacta.'),
                onTap: _retryMigrationFromSettings,
              ),
            ListTile(
              enabled: !widget.temporaryMode && !_rotatingKey,
              leading: _rotatingKey
                  ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.key_outlined),
              title: const Text('Rotar llave de cifrado'),
              subtitle: const Text('Reencripta historial e inventarios dentro de una transacción, sin cambiar su contenido.'),
              onTap: widget.temporaryMode || _rotatingKey ? null : _rotateEncryptionKey,
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Borrar todo el historial'),
              subtitle: Text('${widget.scanStore.history.length} registros guardados'),
              onTap: _clearHistory,
            ),
          ],
        ),
        _Section(
          title: 'Acerca de',
          children: <Widget>[
            if (widget.temporaryMode)
              const ListTile(
                leading: Icon(Icons.visibility_off_outlined),
                title: Text('Modo temporal activo'),
                subtitle: Text('Los datos persistentes no se están utilizando.'),
              ),
            const ListTile(
              leading: Icon(Icons.verified_user_outlined),
              title: Text('Universal Code Scanner 1.0.0'),
              subtitle: Text('Lector local y seguro con historial cifrado, inventario, generador y centro de recuperación. Licencia MIT.'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _update(AppSettings settings) => widget.settings.update(settings);

  Future<void> _updateRetention(int days) async {
    await _update(value.copyWith(historyRetentionDays: days));
    await widget.scanStore.pruneOlderThan(days);
  }

  Future<void> _changeBiometricLock(bool enabled) async {
    if (!enabled) {
      await _update(value.copyWith(biometricLock: false));
      return;
    }
    final bool available = await _biometric.isAvailable();
    final bool authenticated = available && await _biometric.authenticate();
    if (!mounted) return;
    if (authenticated) {
      await _update(value.copyWith(biometricLock: true));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo activar el bloqueo en este dispositivo.')));
    }
  }

  Future<bool> _retryMigration() async {
    final status = await widget.scanStore.retryMigration();
    return status.completed;
  }

  Future<void> _retryMigrationFromSettings() async {
    final bool completed = await _retryMigration();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(completed
          ? 'Migración completada y verificada.'
          : 'La migración sigue pendiente; el origen y el respaldo cifrado se conservaron.'),
    ));
  }

  Future<void> _rotateEncryptionKey() async {
    if (_rotatingKey) return;
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Rotar llave de cifrado'),
            content: const Text('La operación valida y reencripta todos los registros antes de activar la nueva llave. No cierres la aplicación durante el proceso.'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continuar')),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _rotatingKey = true);
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    bool dialogOpen = true;
    final Future<void> dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: <Widget>[CircularProgressIndicator(), SizedBox(width: 16), Expanded(child: Text('Reencriptando datos localmente…'))]),
      ),
    ).whenComplete(() => dialogOpen = false);
    await Future<void>.delayed(Duration.zero);

    EncryptionRotationResult? result;
    Object? failure;
    try {
      result = await widget.dataMaintenanceService.rotateEncryptionKey();
    } on Object catch (error) {
      failure = error;
    } finally {
      if (dialogOpen && navigator.mounted) navigator.pop();
      await dialog;
      if (mounted) setState(() => _rotatingKey = false);
    }
    if (!mounted) return;
    if (failure != null || result == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se modificaron los datos porque la rotación no pudo completarse.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Llave rotada: ${result.historyRecords} lecturas y ${result.inventorySessions} inventarios.'),
    ));
  }

  Future<void> _clearHistory() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Borrar historial'),
            content: const Text('La base local de lecturas quedará vacía. Las sesiones de inventario no se eliminarán.'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Borrar')),
            ],
          ),
        ) ??
        false;
    if (confirmed) await widget.scanStore.clear();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}
