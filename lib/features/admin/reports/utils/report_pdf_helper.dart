import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Opens the system share / print dialog for a PDF byte stream.
Future<void> openReportPdf(
  List<int> bytes,
  String filename,
) async {
  if (bytes.isEmpty) {
    throw StateError('PDF file is empty');
  }
  await Printing.sharePdf(
    bytes: Uint8List.fromList(bytes),
    filename: filename.endsWith('.pdf') ? filename : '$filename.pdf',
  );
}
