import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/services/scan_feedback.dart';

class _FakeTonePlayer implements ScanTonePlayer {
  _FakeTonePlayer({this.failing = false});

  final bool failing;
  int plays = 0;
  int disposals = 0;

  @override
  Future<void> play() async {
    plays++;
    if (failing) throw StateError('no audio device');
  }

  @override
  Future<void> dispose() async => disposals++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        platformCalls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('a successful read plays the tone and vibrates', () async {
    final _FakeTonePlayer player = _FakeTonePlayer();
    final ScanFeedback feedback = ScanFeedback(tonePlayer: player);

    await feedback.success(sound: true, vibration: true);

    expect(player.plays, 1);
    expect(platformCalls.map((MethodCall call) => call.method), contains('HapticFeedback.vibrate'));
  });

  test('each channel honours its own setting', () async {
    final _FakeTonePlayer player = _FakeTonePlayer();
    final ScanFeedback feedback = ScanFeedback(tonePlayer: player);

    await feedback.success(sound: false, vibration: true);
    expect(player.plays, 0);

    platformCalls.clear();
    await feedback.success(sound: true, vibration: false);
    expect(player.plays, 1);
    expect(platformCalls.map((MethodCall call) => call.method), isNot(contains('HapticFeedback.vibrate')));
  });

  test('a player that fails falls back to the system sound and stops retrying', () async {
    final _FakeTonePlayer player = _FakeTonePlayer(failing: true);
    final ScanFeedback feedback = ScanFeedback(tonePlayer: player);

    await feedback.success(sound: true, vibration: false);

    expect(feedback.toneUnavailable, isTrue);
    expect(platformCalls.map((MethodCall call) => call.method), contains('SystemSound.play'));

    await feedback.success(sound: true, vibration: false);
    // The failing player is not called a second time.
    expect(player.plays, 1);
  });

  test('disposal reaches the player', () async {
    final _FakeTonePlayer player = _FakeTonePlayer();
    await ScanFeedback(tonePlayer: player).dispose();

    expect(player.disposals, 1);
  });
}
