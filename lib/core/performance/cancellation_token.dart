import 'package:flutter/foundation.dart';

class OperationCancelledException implements Exception {
  const OperationCancelledException();
  @override
  String toString() => 'OperationCancelledException';
}

class CancellationToken extends ChangeNotifier {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    notifyListeners();
  }

  void throwIfCancelled() {
    if (_cancelled) throw const OperationCancelledException();
  }
}

class BatchProgress extends ChangeNotifier {
  BatchProgress({this.label = ''});

  String label;
  int current = 0;
  int total = 0;

  double? get fraction => total <= 0 ? null : current / total;

  void update({String? label, int? current, int? total}) {
    if (label != null) this.label = label;
    if (current != null) this.current = current;
    if (total != null) this.total = total;
    notifyListeners();
  }
}
