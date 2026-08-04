import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_code_scanner/bootstrap_host.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('application reaches normal or safe startup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BootstrapHost());
    await tester.pump(const Duration(seconds: 5));
    expect(
      find.byWidgetPredicate((Widget widget) =>
          widget is Text && <String>{'Escáner universal', 'Universal scanner', 'Inicio seguro'}.contains(widget.data)),
      findsAtLeastNWidgets(1),
    );
  });
}
