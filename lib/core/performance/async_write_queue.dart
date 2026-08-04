import 'dart:async';

/// Serializes state-changing operations without allowing one failure to poison
/// later writes. Each caller still receives its own value or error.
class AsyncWriteQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final Completer<T> completer = Completer<T>();
    _tail = _tail.then<void>((_) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }
}
