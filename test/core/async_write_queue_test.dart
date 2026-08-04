import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/core/performance/async_write_queue.dart';

void main() {
  test('writes run in submission order even when durations differ', () async {
    final AsyncWriteQueue queue = AsyncWriteQueue();
    final List<int> order = <int>[];
    final Future<void> first = queue.run<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      order.add(1);
    });
    final Future<void> second = queue.run<void>(() async => order.add(2));

    await Future.wait(<Future<void>>[first, second]);
    expect(order, <int>[1, 2]);
  });

  test('a failed write does not block later writes', () async {
    final AsyncWriteQueue queue = AsyncWriteQueue();
    final Future<void> failed = queue.run<void>(() async => throw StateError('expected'));
    final Future<int> recovered = queue.run<int>(() async => 7);

    await expectLater(failed, throwsA(isA<StateError>()));
    expect(await recovered, 7);
  });
}
