/// Future capabilities are disabled by default so stable behaviour remains unchanged.
class FeatureFlags {
  const FeatureFlags({
    this.experimentalParsers = false,
    this.secondaryScannerEngine = false,
    this.ocr = false,
    this.nfc = false,
    this.urlReputation = false,
    this.productLookup = false,
    this.encryptedSync = false,
    this.enterpriseApi = false,
    this.kioskMode = false,
  });

  final bool experimentalParsers;
  final bool secondaryScannerEngine;
  final bool ocr;
  final bool nfc;
  final bool urlReputation;
  final bool productLookup;
  final bool encryptedSync;
  final bool enterpriseApi;
  final bool kioskMode;

  FeatureFlags copyWith({
    bool? experimentalParsers,
    bool? secondaryScannerEngine,
    bool? ocr,
    bool? nfc,
    bool? urlReputation,
    bool? productLookup,
    bool? encryptedSync,
    bool? enterpriseApi,
    bool? kioskMode,
  }) => FeatureFlags(
        experimentalParsers: experimentalParsers ?? this.experimentalParsers,
        secondaryScannerEngine: secondaryScannerEngine ?? this.secondaryScannerEngine,
        ocr: ocr ?? this.ocr,
        nfc: nfc ?? this.nfc,
        urlReputation: urlReputation ?? this.urlReputation,
        productLookup: productLookup ?? this.productLookup,
        encryptedSync: encryptedSync ?? this.encryptedSync,
        enterpriseApi: enterpriseApi ?? this.enterpriseApi,
        kioskMode: kioskMode ?? this.kioskMode,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'experimentalParsers': experimentalParsers,
        'secondaryScannerEngine': secondaryScannerEngine,
        'ocr': ocr,
        'nfc': nfc,
        'urlReputation': urlReputation,
        'productLookup': productLookup,
        'encryptedSync': encryptedSync,
        'enterpriseApi': enterpriseApi,
        'kioskMode': kioskMode,
      };

  factory FeatureFlags.fromJson(Map<String, dynamic> json) => FeatureFlags(
        experimentalParsers: json['experimentalParsers'] as bool? ?? false,
        secondaryScannerEngine: json['secondaryScannerEngine'] as bool? ?? false,
        ocr: json['ocr'] as bool? ?? false,
        nfc: json['nfc'] as bool? ?? false,
        urlReputation: json['urlReputation'] as bool? ?? false,
        productLookup: json['productLookup'] as bool? ?? false,
        encryptedSync: json['encryptedSync'] as bool? ?? false,
        enterpriseApi: json['enterpriseApi'] as bool? ?? false,
        kioskMode: json['kioskMode'] as bool? ?? false,
      );
}
