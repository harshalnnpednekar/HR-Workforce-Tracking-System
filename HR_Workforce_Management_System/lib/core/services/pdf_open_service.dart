import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class PdfOpenService {
  static Future<void> openPdfBytes(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final safeName = _sanitizeFileName(fileName);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$safeName');

    await file.writeAsBytes(bytes, flush: true);

    final result = await OpenFilex.open(file.path, type: 'application/pdf');
    if (result.type != ResultType.done) {
      throw Exception(
        result.message.isEmpty ? 'Unable to open PDF.' : result.message,
      );
    }
  }

  static Future<void> openPdfFromUrl(String url, {String? fileName}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw Exception('Invalid PDF URL.');
    }

    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to download PDF (${response.statusCode}).');
    }

    final inferredName = fileName ?? _fileNameFromUri(uri) ?? 'document.pdf';
    await openPdfBytes(response.bodyBytes, fileName: inferredName);
  }

  static String _sanitizeFileName(String fileName) {
    final cleaned = fileName.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (cleaned.isEmpty) {
      return 'document.pdf';
    }
    return cleaned.toLowerCase().endsWith('.pdf') ? cleaned : '$cleaned.pdf';
  }

  static String? _fileNameFromUri(Uri uri) {
    if (uri.pathSegments.isEmpty) {
      return null;
    }
    final last = uri.pathSegments.last.trim();
    if (last.isEmpty) {
      return null;
    }
    return last;
  }
}
