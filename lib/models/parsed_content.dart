enum ContentKind {
  url,
  wifi,
  contact,
  event,
  email,
  phone,
  sms,
  geo,
  otp,
  gs1,
  isbn,
  product,
  payment,
  crypto,
  identity,
  binary,
  text,
}

class ParsedContent {
  const ParsedContent({
    required this.kind,
    required this.title,
    required this.fields,
    this.summary,
    this.sensitive = false,
  });

  final ContentKind kind;
  final String title;
  final String? summary;
  final Map<String, String> fields;
  final bool sensitive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.name,
        'title': title,
        'summary': summary,
        'fields': fields,
        'sensitive': sensitive,
      };

  factory ParsedContent.fromJson(Map<String, dynamic> json) {
    return ParsedContent(
      kind: ContentKind.values.byName(json['kind'] as String? ?? 'text'),
      title: json['title'] as String? ?? 'Texto',
      summary: json['summary'] as String?,
      fields: Map<String, dynamic>.from(json['fields'] as Map? ?? const <String, dynamic>{})
          .map((String key, dynamic value) => MapEntry<String, String>(key, '$value')),
      sensitive: json['sensitive'] as bool? ?? false,
    );
  }
}
