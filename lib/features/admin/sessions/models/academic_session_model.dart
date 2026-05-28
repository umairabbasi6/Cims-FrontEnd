class AcademicSessionModel {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final bool isActive;
  final DateTime createdAt;

  const AcademicSessionModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.isActive,
    required this.createdAt,
  });

  factory AcademicSessionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AcademicSessionModel(
      id: json['id'] as int,
      name: json['name'] as String,
      startDate: DateTime.parse(
        json['start_date'] as String,
      ),
      endDate: DateTime.parse(
        json['end_date'] as String,
      ),
      isCurrent: json['is_current'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'start_date':
            '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'end_date':
            '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        'is_current': isCurrent,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };
}

class AcademicSessionListResponse {
  final int total;
  final List<AcademicSessionModel> sessions;

  const AcademicSessionListResponse({
    required this.total,
    required this.sessions,
  });

  factory AcademicSessionListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['sessions'] as List<dynamic>? ?? [];
    return AcademicSessionListResponse(
      total: json['total'] as int? ?? raw.length,
      sessions: raw
          .map(
            (e) => AcademicSessionModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
