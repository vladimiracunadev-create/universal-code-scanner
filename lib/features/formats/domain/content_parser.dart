import 'package:universal_code_scanner/models/parsed_content.dart';

abstract interface class ContentParser {
  String get id;
  int get priority;
  bool canParse(String rawValue);
  ParsedContent parse(String rawValue);
}
