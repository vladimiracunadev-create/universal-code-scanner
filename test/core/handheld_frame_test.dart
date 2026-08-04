import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/app.dart';

void main() {
  const Key content = Key('content');

  Widget frame() => const MaterialApp(
        home: HandheldFrame(
          child: SizedBox.expand(key: content, child: ColoredBox(color: Color(0xFF006B66))),
        ),
      );

  Future<Rect> layout(WidgetTester tester, Size viewport) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(frame());
    return tester.getRect(find.byKey(content));
  }

  testWidgets('a phone-sized viewport is filled edge to edge', (WidgetTester tester) async {
    final Rect box = await layout(tester, const Size(400, 900));

    expect(box.left, 0);
    expect(box.width, 400);
  });

  testWidgets('exactly at the threshold the viewport is still filled', (WidgetTester tester) async {
    final Rect box = await layout(tester, const Size(HandheldFrame.maxWidth, 900));

    expect(box.left, 0);
    expect(box.width, HandheldFrame.maxWidth);
  });

  testWidgets('a wide viewport is centred at handheld width', (WidgetTester tester) async {
    const double viewport = 1600;
    final Rect box = await layout(tester, const Size(viewport, 900));

    expect(box.width, HandheldFrame.maxWidth);
    // Centred: the margin is identical on both sides.
    expect(box.left, viewport - box.right);
    expect(box.left, (viewport - HandheldFrame.maxWidth) / 2);
  });
}
