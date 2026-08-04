import 'package:universal_code_scanner/features/formats/domain/content_parser.dart';
import 'package:universal_code_scanner/models/parsed_content.dart';
import 'package:universal_code_scanner/services/content_interpreter.dart';

class ContentParserRegistry {
  ContentParserRegistry._() : _parsers = <ContentParser>[const LegacyContentParser()];
  static final ContentParserRegistry instance = ContentParserRegistry._();

  final List<ContentParser> _parsers;
  List<ContentParser> get parsers => List<ContentParser>.unmodifiable(_parsers);

  void register(ContentParser parser) {
    _parsers.removeWhere((ContentParser item) => item.id == parser.id);
    _parsers.add(parser);
    _parsers.sort((ContentParser a, ContentParser b) => b.priority.compareTo(a.priority));
  }

  void unregister(String id) => _parsers.removeWhere((ContentParser item) => item.id == id && id != 'builtin-v2');

  ParsedContent parse(String rawValue) {
    for (final ContentParser parser in _parsers) {
      if (parser.canParse(rawValue)) return parser.parse(rawValue);
    }
    return ContentInterpreter.parse(rawValue);
  }
}

class LegacyContentParser implements ContentParser {
  const LegacyContentParser();
  @override
  String get id => 'builtin-v2';
  @override
  int get priority => -1000;
  @override
  bool canParse(String rawValue) => true;
  @override
  ParsedContent parse(String rawValue) => ContentInterpreter.parse(rawValue);
}
