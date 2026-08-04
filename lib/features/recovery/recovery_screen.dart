import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_code_scanner/core/diagnostics/app_diagnostics.dart';
import 'package:universal_code_scanner/core/recovery/recovery_issue.dart';
import 'package:universal_code_scanner/core/recovery/recovery_service.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({required this.service, this.retryMigration, super.key});
  final RecoveryService service;
  final Future<bool> Function()? retryMigration;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  late Future<List<RecoveryIssue>> _issues;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _issues = widget.service.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de recuperación'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Copiar paquete de recuperación',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: await widget.service.exportBundle()));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paquete de recuperación copiado.')));
            },
            icon: const Icon(Icons.inventory_2_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<RecoveryIssue>>(
        future: _issues,
        builder: (BuildContext context, AsyncSnapshot<List<RecoveryIssue>> snapshot) {
          final List<RecoveryIssue> issues = snapshot.data ?? const <RecoveryIssue>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Diagnóstico privado'),
                  subtitle: Text('${AppDiagnostics.instance.entries.length} eventos técnicos sin cargas escaneadas'),
                  trailing: IconButton(
                    tooltip: 'Copiar diagnóstico',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: AppDiagnostics.instance.exportJson()));
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diagnóstico copiado.')));
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Elementos detectados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.waiting) const Center(child: CircularProgressIndicator()),
              if (snapshot.connectionState != ConnectionState.waiting && issues.isEmpty)
                const Card(child: ListTile(leading: Icon(Icons.check_circle_outline), title: Text('No hay elementos pendientes'))),
              ...issues.map((RecoveryIssue issue) => Card(
                    child: ListTile(
                      leading: Icon(issue.state == RecoveryIssueState.unresolved ? Icons.warning_amber_rounded : Icons.task_alt),
                      title: Text('${issue.entityType.name} · ${issue.code}'),
                      subtitle: Text('ID técnico: ${issue.entityId}\nDetectado: ${issue.detectedAt.toLocal()}\nEstado: ${issue.state.name}'),
                      isThreeLine: true,
                      trailing: issue.state == RecoveryIssueState.unresolved
                          ? PopupMenuButton<String>(
                              onSelected: (String action) => _handle(issue, action),
                              itemBuilder: (_) => <PopupMenuEntry<String>>[
                                if (issue.encryptedPayload != null)
                                  const PopupMenuItem(value: 'retry', child: Text('Reintentar recuperación')),
                                if (issue.entityType == RecoveryEntityType.migration && widget.retryMigration != null)
                                  const PopupMenuItem(value: 'retry_migration', child: Text('Reintentar migración')),
                                const PopupMenuItem(value: 'discard', child: Text('Descartar registro afectado')),
                                const PopupMenuItem(value: 'resolved', child: Text('Marcar revisado')),
                              ],
                            )
                          : null,
                    ),
                  )),
              if (issues.any((RecoveryIssue item) => item.state != RecoveryIssueState.unresolved))
                TextButton.icon(
                  onPressed: () async {
                    await widget.service.repository.clearResolved();
                    setState(_reload);
                  },
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('Limpiar elementos resueltos'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handle(RecoveryIssue issue, String action) async {
    bool success = true;
    if (action == 'retry') success = await widget.service.retry(issue);
    if (action == 'retry_migration') {
      success = await widget.retryMigration?.call() ?? false;
      if (success) await widget.service.repository.mark(issue.id, RecoveryIssueState.recovered);
    }
    if (action == 'discard') {
      if (!mounted) return;
      final bool confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Descartar elemento'),
              content: const Text('Se eliminará únicamente el registro afectado. Los demás datos permanecerán intactos.'),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Descartar')),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
      await widget.service.discard(issue);
    }
    if (action == 'resolved') await widget.service.repository.mark(issue.id, RecoveryIssueState.recovered);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Acción completada.' : 'No fue posible recuperar el elemento con la llave disponible.'),
    ));
  }
}
