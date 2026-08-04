import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:universal_code_scanner/core/performance/cancellation_token.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

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
  }) async {
    await pdfrxFlutterInitialize();
    final FilePickerResult? selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf'],
      allowMultiple: false,
      withData: false,
    );
    final String? path = selection?.files.single.path;
    if (path == null || path.isEmpty) return const <RenderedPdfPage>[];

    final PdfDocument document = await PdfDocument.openFile(path);
    final Directory temporaryDirectory = await getTemporaryDirectory();
    final Directory outputDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}ucs_pdf_${DateTime.now().microsecondsSinceEpoch}',
    );
    await outputDirectory.create(recursive: true);

    final List<RenderedPdfPage> rendered = <RenderedPdfPage>[];
    try {
      final int count = document.pages.length < maxPages ? document.pages.length : maxPages;
      for (int index = 0; index < count; index++) {
        cancellationToken?.throwIfCancelled();
        onProgress?.call(index + 1, count);
        final PdfPage page = document.pages[index];
        final double scale = _renderScale(page.width, page.height);
        final PdfPageRenderCancellationToken renderToken = page.createCancellationToken();
        void cancelRender() {
          if (cancellationToken?.isCancelled ?? false) renderToken.cancel();
        }
        cancellationToken?.addListener(cancelRender);
        cancelRender();
        final PdfImage? pdfImage;
        try {
          pdfImage = await page.render(
            fullWidth: page.width * scale,
            fullHeight: page.height * scale,
            backgroundColor: 0xFFFFFFFF,
            cancellationToken: renderToken,
          );
        } finally {
          cancellationToken?.removeListener(cancelRender);
        }
        cancellationToken?.throwIfCancelled();
        if (pdfImage == null) continue;
        try {
          final ui.Image image = await pdfImage.createImage();
          try {
            final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
            if (byteData == null) continue;
            final String outputPath = '${outputDirectory.path}${Platform.pathSeparator}page_${index + 1}.png';
            await File(outputPath).writeAsBytes(byteData.buffer.asUint8List(), flush: true);
            rendered.add(RenderedPdfPage(pageNumber: index + 1, imagePath: outputPath));
          } finally {
            image.dispose();
          }
        } finally {
          pdfImage.dispose();
        }
      }
      if (rendered.isEmpty && await outputDirectory.exists()) {
        await outputDirectory.delete(recursive: true);
      }
      return rendered;
    } catch (_) {
      await cleanup(rendered);
      if (await outputDirectory.exists()) {
        await outputDirectory.delete(recursive: true);
      }
      rethrow;
    } finally {
      await document.dispose();
    }
  }

  static Future<void> cleanup(Iterable<RenderedPdfPage> pages) async {
    final Set<String> directories = <String>{};
    for (final RenderedPdfPage page in pages) {
      final File file = File(page.imagePath);
      directories.add(file.parent.path);
      if (await file.exists()) await file.delete();
    }
    for (final String path in directories) {
      final Directory directory = Directory(path);
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }

  static double _renderScale(double width, double height) {
    final double longest = width > height ? width : height;
    if (longest <= 0) return 2.5;
    return (2400 / longest).clamp(1.5, 4.0).toDouble();
  }
}
