import 'package:intl/intl.dart';

class LeaveRequestModel {
  final int id;
  final int teacherId;
  final String teacherName;
  final String staffIdCode;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // PENDING, APPROVED, REJECTED
  final String? reviewedBy;
  final DateTime createdAt;

  const LeaveRequestModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.staffIdCode,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.reviewedBy,
    required this.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime sDate = DateTime.now();
    DateTime eDate = DateTime.now();
    DateTime cDate = DateTime.now();

    if (json['start_date'] != null) {
      sDate = DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now();
    }
    if (json['end_date'] != null) {
      eDate = DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now();
    }
    if (json['created_at'] != null) {
      cDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    String tName = 'Teacher';
    String tCode = '—';
    if (json['teacher'] is Map) {
      tName = json['teacher']['full_name'] as String? ?? 'Teacher';
      tCode = json['teacher']['staff_id_code'] as String? ?? '—';
    }

    return LeaveRequestModel(
      id: json['id'] as int? ?? 0,
      teacherId: json['teacher_id'] as int? ?? 0,
      teacherName: tName,
      staffIdCode: tCode,
      startDate: sDate,
      endDate: eDate,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      reviewedBy: json['reviewed_by'] as String?,
      createdAt: cDate,
    );
  }

  String get formattedRange {
    final fmt = DateFormat('dd MMM yyyy');
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return fmt.format(startDate);
    }
    return '${fmt.format(startDate)} – ${fmt.format(endDate)}';
  }

  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
}
