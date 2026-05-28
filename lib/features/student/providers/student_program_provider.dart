import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/programs/providers/program_provider.dart';
import 'package:cims/features/teacher/results/providers/results_api_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';

class ProgramStageRow {
  final int stage;
  final String semesterLabel;
  final String subjectsLabel;
  final String creditHours;
  final String gpa;
  final String status;

  const ProgramStageRow({
    required this.stage,
    required this.semesterLabel,
    required this.subjectsLabel,
    required this.creditHours,
    required this.gpa,
    required this.status,
  });
}

class StudentProgramOverview {
  final StudentApiModel student;
  final String programCode;
  final String programTitle;
  final String semesterValue;
  final String sessionLabel;
  final String creditsValue;
  final String creditsPill;
  final String structureSubtitle;
  final List<ProgramStageRow> stages;

  const StudentProgramOverview({
    required this.student,
    required this.programCode,
    required this.programTitle,
    required this.semesterValue,
    required this.sessionLabel,
    required this.creditsValue,
    required this.creditsPill,
    required this.structureSubtitle,
    required this.stages,
  });
}

String _ordinalStage(int stage) {
  const suffixes = ['th', 'st', 'nd', 'rd'];
  final mod100 = stage % 100;
  final mod10 = stage % 10;
  if (mod100 >= 11 && mod100 <= 13) {
    return '${stage}th';
  }
  switch (mod10) {
    case 1:
      return '${stage}st';
    case 2:
      return '${stage}nd';
    case 3:
      return '${stage}rd';
    default:
      return '$stage${suffixes[0]}';
  }
}

String _stageStatus(int stage, int currentStage) {
  if (stage < currentStage) return 'Passed';
  if (stage == currentStage) return 'Active';
  return 'Pending';
}

double? _gpaFromResultMap(Map<String, dynamic> row) {
  final keys = ['cgpa', 'gpa', 'stage_gpa'];
  for (final k in keys) {
    final v = row[k];
    if (v is num) return v.toDouble();
  }
  final pct = row['percentage'];
  if (pct is num) {
    if (pct >= 85) return 4.0;
    if (pct >= 80) return 3.7;
    if (pct >= 75) return 3.3;
    if (pct >= 70) return 3.0;
    if (pct >= 65) return 2.7;
    if (pct >= 60) return 2.3;
    if (pct >= 50) return 2.0;
    return 0.0;
  }
  return null;
}

final studentProgramOverviewProvider =
    FutureProvider.autoDispose<StudentProgramOverview?>(
  (ref) async {
    final student = await ref.watch(currentStudentProvider.future);
    if (student == null) return null;

    final program = student.program;
    if (program == null || program.id == 0) return null;

    final session = await ref.watch(
      currentAcademicSessionProvider.future,
    );
    final sessionId = session?.id;

    final subjects = await ref.read(
      subjectRepositoryProvider,
    ).listSubjects(programId: program.id);

    final programRepo = ref.read(programRepositoryProvider);
    final stagesResponse = await programRepo.getProgramStages(
      program.id,
    );

    final gpaByStage = <int, double>{};
    if (sessionId != null) {
      try {
        final resultsRepo = ref.read(resultsRepositoryProvider);
        final rows = await resultsRepo.studentResults(
          student.id,
          sessionId: sessionId,
        );
        for (final row in rows) {
          final stageRaw = row['stage'] ?? row['current_stage'];
          final stage = stageRaw is int
              ? stageRaw
              : int.tryParse('$stageRaw');
          if (stage == null) continue;
          final gpa = _gpaFromResultMap(row);
          if (gpa != null) gpaByStage[stage] = gpa;
        }
      } catch (_) {}
    }

    final subjectsByStage = <int, List<String>>{};
    final creditsByStage = <int, double>{};
    for (final s in subjects) {
      subjectsByStage.putIfAbsent(s.stage, () => []).add(s.name);
      creditsByStage[s.stage] =
          (creditsByStage[s.stage] ?? 0) + s.creditHours;
    }

    final totalCredits = creditsByStage.values.fold<double>(
      0,
      (a, b) => a + b,
    );
    var earnedCredits = 0.0;
    for (final entry in creditsByStage.entries) {
      if (entry.key < student.currentStage) {
        earnedCredits += entry.value;
      }
    }

    final pctComplete = totalCredits > 0
        ? ((earnedCredits / totalCredits) * 100).round()
        : 0;

    final stageRows = <ProgramStageRow>[];
    for (final stageInfo in stagesResponse.stages) {
      final stage = stageInfo.stage;
      final names = subjectsByStage[stage] ?? [];
      final credits = creditsByStage[stage] ?? 0;
      final status = _stageStatus(stage, student.currentStage);
      final gpa = gpaByStage[stage];

      stageRows.add(
        ProgramStageRow(
          stage: stage,
          semesterLabel: _ordinalStage(stage),
          subjectsLabel:
              names.isEmpty ? '—' : names.join(', '),
          creditHours: credits > 0 ? credits.round().toString() : '—',
          gpa:
              status == 'Pending'
                  ? '—'
                  : (gpa != null ? gpa.toStringAsFixed(1) : '—'),
          status: status,
        ),
      );
    }

    return StudentProgramOverview(
      student: student,
      programCode: program.code,
      programTitle: program.name,
      semesterValue: _ordinalStage(student.currentStage),
      sessionLabel: session?.name ?? 'Current session',
      creditsValue:
          totalCredits > 0
              ? '${earnedCredits.round()}/${totalCredits.round()}'
              : '—',
      creditsPill:
          totalCredits > 0 ? '$pctComplete% complete' : 'In progress',
      structureSubtitle:
          program.award.isNotEmpty
              ? program.award
              : '${program.name} · ${program.programType}',
      stages: stageRows,
    );
  },
);
