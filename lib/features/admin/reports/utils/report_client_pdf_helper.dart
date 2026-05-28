import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a class result sheet PDF dynamically on the client.
Future<Uint8List> generateClassResultsPdf({
  required String programName,
  required String stageLabel,
  required String sessionName,
  required List<Map<String, dynamic>> studentsResults,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Capital Institute of Para Medical Sciences',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Official Class Results Sheet',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Divider(),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          // Metadata
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Program: $programName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Stage: $stageLabel'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Session: $sessionName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table
          pw.TableHelper.fromTextArray(
            headers: [
              'Roll No',
              'Student Name',
              'Total Marks',
              'Percentage',
              'CGPA',
              'Result',
            ],
            data: studentsResults.map((s) {
              final studentCode = s['student_id_code']?.toString() ?? '—';
              final studentName = s['full_name']?.toString() ?? '—';
              final totalMarks = s['total_marks']?.toString() ?? '0';
              final grandTotal = s['grand_total']?.toString() ?? '0';
              final pct = s['overall_percentage']?.toString() ?? '0';
              final cgpa = s['cgpa']?.toString() ?? '0';
              final status = s['overall_result']?.toString() ?? 'Fail';

              return [
                studentCode,
                studentName,
                '$totalMarks / $grandTotal',
                '$pct%',
                cgpa,
                status,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
          ),
          pw.SizedBox(height: 40),
          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 120, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey700)))),
                  pw.SizedBox(height: 4),
                  pw.Text('Prepared By', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 120, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey700)))),
                  pw.SizedBox(height: 4),
                  pw.Text('Controller of Exams', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 120, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey700)))),
                  pw.SizedBox(height: 4),
                  pw.Text('Principal Signature', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ];
      },
    ),
  );

  return pdf.save();
}

/// Generates a class attendance report PDF with shortage warnings dynamically.
Future<Uint8List> generateClassAttendancePdf({
  required String programName,
  required String stageLabel,
  required String sessionName,
  required List<Map<String, dynamic>> studentsAttendance,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Capital Institute of Para Medical Sciences',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Class Attendance Shortage Report',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Divider(),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          // Metadata
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Program: $programName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Stage: $stageLabel'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Session: $sessionName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table
          pw.TableHelper.fromTextArray(
            headers: [
              'Roll No',
              'Student Name',
              'Attendance %',
              'Shortage Warning',
            ],
            data: studentsAttendance.map((s) {
              final studentCode = s['student_id_code']?.toString() ?? '—';
              final studentName = s['full_name']?.toString() ?? '—';
              final att = s['attendance_percentage']?.toString() ?? '—';
              final hasShortage = s['has_shortage'] as bool? ?? false;

              return [
                studentCode,
                studentName,
                att.isNotEmpty ? '$att%' : '—',
                hasShortage ? 'YES (SHORTAGE)' : 'NO',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
          ),
          pw.SizedBox(height: 40),
          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey700)))),
                  pw.SizedBox(height: 4),
                  pw.Text('Class Instructor', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey700)))),
                  pw.SizedBox(height: 4),
                  pw.Text('Principal Signature', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ];
      },
    ),
  );

  return pdf.save();
}
