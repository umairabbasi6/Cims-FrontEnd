import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<void> saveAndShareCsv({
  required String csvString,
  required String fileName,
}) async {
  final bytes = Uint8List.fromList(csvString.codeUnits);
  await Printing.sharePdf(
    bytes: bytes,
    filename: fileName,
  );
}
