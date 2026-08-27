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

  /// Removes a parser by id. The built-in one is protected: without it the
  /// registry could end up with no parser willing to accept a payload, and
  /// every scan would fall through to the defensive branch in `parse`.
  void unregister(String id) => _parsers.removeWhere((ContentParser item) => item.id == id && id != 'builtin-v2');

  ParsedContent parse(String rawValue) {
    for (final ContentParser parser in _parsers) {
      if (parser.canParse(rawValue)) return parser.parse(rawValue);
    }
    // Unreachable while `LegacyContentParser` is registered — it accepts every
    // payload and cannot be unregistered. Kept as a deliberate guarantee that
    // this method always returns a `ParsedContent` rather than throwing.
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
