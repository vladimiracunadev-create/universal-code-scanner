import 'package:universal_code_scanner/core/performance/cancellation_token.dart';

class RenderedPdfPage {
  const RenderedPdfPage({required this.pageNumber, required this.imagePath});

  final int pageNumber;
  final String imagePath;
}

class PdfPageRenderer {
  static Future<List<RenderedPdfPage>> pickAndRender({
    int maxPages = 50,
    CancellationToken? cancellationToken,
    void Function(int current, int total)? onProgress,
  }) {
    throw UnsupportedError('La lectura de PDF no está disponible en esta plataforma.');
  }

  static Future<void> cleanup(Iterable<RenderedPdfPage> pages) async {}
}
