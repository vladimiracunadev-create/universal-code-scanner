import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_code_scanner/app.dart';
import 'package:universal_code_scanner/bootstrap.dart';
import 'package:universal_code_scanner/core/diagnostics/app_diagnostics.dart';
import 'package:universal_code_scanner/core/diagnostics/startup_failure.dart';
import 'package:universal_code_scanner/services/settings_repository.dart';

class BootstrapHost extends StatefulWidget {
  const BootstrapHost({super.key});

  @override
  State<BootstrapHost> createState() => _BootstrapHostState();
}

class _BootstrapHostState extends State<BootstrapHost> {
  Future<AppServices>? _future;
  StartupFailure? _failure;

  @override
  void initState() {
    super.initState();
    _retry();
  }

  void _retry({bool temporary = false}) {
    setState(() {
      _failure = null;
      _future = AppBootstrapper.initialize(temporary: temporary).catchError((Object error, StackTrace stack) {
        AppDiagnostics.instance.record(error, stack, area: temporary ? 'bootstrap_temporary' : 'bootstrap');
        _failure = StartupFailure.from(error, stack);
        throw error;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final StartupFailure? failure = _failure;
    if (failure != null) return _StartupRecovery(failure: failure, retry: _retry);
    return FutureBuilder<AppServices>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<AppServices> snapshot) {
        if (snapshot.hasData) {
          final AppServices services = snapshot.requireData;
          return UniversalCodeScannerApp(
            scanStore: services.scanStore,
            inventoryStore: services.inventoryStore,
            settingsStore: services.settingsStore,
            recoveryRepository: services.recoveryRepository,
            recoveryService: services.recoveryService,
            dataMaintenanceService: services.dataMaintenanceService,
            temporaryMode: services.temporary,
          );
        }
        if (snapshot.hasError && _failure != null) return _StartupRecovery(failure: _failure!, retry: _retry);
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: CircularProgressIndicator(semanticsLabel: 'Inicializando aplicación'))),
        );
      },
    );
  }
}

class _StartupRecovery extends StatelessWidget {
  const _StartupRecovery({required this.failure, required this.retry});
  final StartupFailure failure;
  final void Function({bool temporary}) retry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.health_and_safety_outlined, size: 64),
                        const SizedBox(height: 16),
                        Text('Inicio seguro', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(failure.message, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        SelectableText('Diagnóstico: ${failure.errorType} · ${failure.stackFingerprint}'),
                        const SizedBox(height: 20),
                        FilledButton.icon(onPressed: () => retry(), icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => retry(temporary: true),
                          icon: const Icon(Icons.visibility_off_outlined),
                          label: const Text('Abrir sin historial ni inventarios persistentes'),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async {
                            await SettingsRepository().resetNonSensitive();
                            retry();
                          },
                          icon: const Icon(Icons.settings_backup_restore),
                          label: const Text('Restablecer preferencias visuales'),
                        ),
                        TextButton.icon(
                          onPressed: () => Clipboard.setData(ClipboardData(text: AppDiagnostics.instance.exportJson())),
                          icon: const Icon(Icons.copy_all_outlined),
                          label: const Text('Copiar diagnóstico privado'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'El diagnóstico no incluye códigos escaneados, enlaces, contraseñas, secretos OTP, notas ni productos.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
