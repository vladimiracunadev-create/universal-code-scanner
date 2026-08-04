import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/features/formats/domain/content_parser.dart';
import 'package:universal_code_scanner/features/formats/domain/content_parser_registry.dart';
import 'package:universal_code_scanner/models/parsed_content.dart';

class _TestParser implements ContentParser {
  @override
  String get id => 'test-parser';
  @override
  int get priority => 1000;
  @override
  bool canParse(String rawValue) => rawValue.startsWith('TEST:');
  @override
  ParsedContent parse(String rawValue) => const ParsedContent(
        kind: ContentKind.text,
        title: 'Plugin de prueba',
        fields: <String, String>{'ok': 'true'},
      );
}

void main() {
  test('custom parser is isolated and removable', () {
    final ContentParserRegistry registry = ContentParserRegistry.instance;
    registry.register(_TestParser());
    expect(registry.parse('TEST:value').title, 'Plugin de prueba');
    registry.unregister('test-parser');
    expect(registry.parse('TEST:value').title, isNot('Plugin de prueba'));
  });
}
