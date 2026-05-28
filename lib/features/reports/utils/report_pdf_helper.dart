import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ReportPdfHelper {
  static Future<String?> savePdfBytes(
      Uint8List bytes, String fileName) async {
    try {
      if (kIsWeb) {
        // Handle web download if necessary.
        // Usually requires dart:html or equivalent approach for web.
        return null;
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      return null;
    }
  }
}
