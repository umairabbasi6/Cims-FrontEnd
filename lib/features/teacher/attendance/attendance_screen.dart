import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/admin/subjects/models/subject_api_model.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/enrollments/providers/enrollment_provider.dart';
import 'package:cims/features/teacher/attendance/providers/attendance_api_provider.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const AttendanceScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  int? _selectedSubjectId;
  int? _selectedSessionId;
  String? _selectedClassKey;
  String selectedType = 'Theory';
  String selectedSubject = '';
  DateTime _selectedDate = DateTime.now();
  late final TextEditingController _dateController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: _formatDisplayDate(_selectedDate),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDisplayDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/$year';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.darkSurface,
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    surface: Colors.white,
                    onSurface: AppColors.text,
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDisplayDate(picked);
      });
    }
  }

  String _statusToCode(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'P';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.late:
        return 'L';
      case AttendanceStatus.sick:
        return 'S';
    }
  }

  void _markAllStatus(List<StudentAttendance> students, AttendanceStatus status) {
    setState(() {
      for (var s in students) {
        s.status = status;
      }
    });
  }

  Widget _classBulkButton({
    required String shortLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .4)),
        ),
        child: Text(
          shortLabel,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _saveAttendance(List<StudentAttendance> students) async {
    if (_selectedSubjectId == null || _selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject and session.')),
      );
      return;
    }

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students enrolled in this subject.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentStaff = ref.read(currentStaffProvider).value;
      final staffId = currentStaff?.id ?? 1;

      final subjects = ref.read(subjectsListProvider).value ?? [];
      final selectedSub = subjects.firstWhere(
        (s) => s.id == _selectedSubjectId,
        orElse: () => subjects.first,
      );
      final stage = selectedSub.stage;

      final dateStr = _formatDate(_selectedDate);

      final sessionBody = {
        'subject_id': _selectedSubjectId,
        'staff_id': staffId,
        'session_id': _selectedSessionId,
        'stage': stage,
        'session_date': dateStr,
        'class_type': selectedType.toUpperCase(),
        'notes': 'Recorded via Flutter App',
      };

      final repo = ref.read(attendanceRepositoryProvider);
      final sessionResult = await repo.createSession(sessionBody);
      final createdSessionId = sessionResult['id'] as int?;

      if (createdSessionId == null) {
        throw Exception('Failed to create attendance session');
      }

      final records = students.map((s) => {
        'student_id': s.id,
        'status': _statusToCode(s.status),
      }).toList();

      final markBody = {
        'records': records,
      };

      await repo.bulkMark(createdSessionId, markBody);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(attendanceSessionsListProvider(AttendanceSessionsArgs(subjectId: _selectedSubjectId, sessionId: _selectedSessionId)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = AppSession.currentRole.toLowerCase() == 'teacher';
    final teacherSubsAsync = ref.watch(teacherAssignedSubjectsProvider);
    final allSubjectsAsync = ref.watch(subjectsListProvider);
    final sessionsAsync = ref.watch(sessionsListProvider);
    final currentSessionAsync = ref.watch(currentAcademicSessionProvider);

    // If teacher, display ONLY assigned subjects; if admin or if empty, show all subjects
    final subjectsAsync = isTeacher
        ? (teacherSubsAsync.value != null && teacherSubsAsync.value!.isNotEmpty ? teacherSubsAsync : allSubjectsAsync)
        : allSubjectsAsync;

    // enrollments require a selected subject id; pass sessionId: null so all enrolled students for this subject are returned
    final enrollmentsAsync = _selectedSubjectId != null
      ? ref.watch(subjectEnrollmentsProvider(SubjectEnrollmentsArgs(subjectId: _selectedSubjectId!, sessionId: null)))
      : const AsyncValue.data(<Map<String, dynamic>>[]);

    final attendanceSessionsAsync = ref.watch(attendanceSessionsListProvider(AttendanceSessionsArgs(subjectId: _selectedSubjectId, sessionId: _selectedSessionId)));

    // initialize default selections when providers become available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (subjectsAsync is AsyncData) {
        final subjects = subjectsAsync.value;
        if (subjects != null && subjects.isNotEmpty) {
          final Map<String, String> classMap = {};
          for (final s in subjects) {
            final progName = s.program?.name ?? 'Class';
            final stageName = s.stage > 0 ? 'Semester ${s.stage}' : 'Stage ${s.stage}';
            final key = '${s.program?.id ?? 0}_${s.stage}';
            classMap[key] = '$progName · $stageName';
          }

          if (_selectedClassKey == null || !classMap.containsKey(_selectedClassKey)) {
            final firstKey = classMap.keys.first;
            final matching = subjects.where((s) => '${s.program?.id ?? 0}_${s.stage}' == firstKey).toList();
            setState(() {
              _selectedClassKey = firstKey;
              if (matching.isNotEmpty) {
                _selectedSubjectId = matching.first.id;
                selectedSubject = matching.first.name;
              }
            });
          } else if (_selectedSubjectId == null) {
            final matching = subjects.where((s) => '${s.program?.id ?? 0}_${s.stage}' == _selectedClassKey).toList();
            setState(() {
              if (matching.isNotEmpty) {
                _selectedSubjectId = matching.first.id;
                selectedSubject = matching.first.name;
              } else {
                _selectedSubjectId = subjects.first.id;
                selectedSubject = subjects.first.name;
              }
            });
          }
        }
      }
      if (_selectedSessionId == null) {
        final cur = currentSessionAsync.value;
        if (cur != null) {
          setState(() => _selectedSessionId = cur.id);
        } else if (sessionsAsync is AsyncData) {
          final sessions = sessionsAsync.value;
          if (sessions != null && sessions.isNotEmpty) {
            final active = sessions.where((s) => s.isCurrent).firstOrNull ?? sessions.first;
            setState(() => _selectedSessionId = active.id);
          }
        }
      }
    });

    final students = enrollmentsAsync.when(
      data: (rows) => _mapEnrollmentsToStudents(rows),
      loading: () => <StudentAttendance>[],
      error: (_, __) => <StudentAttendance>[],
    );

    final recentSessions = attendanceSessionsAsync.when(
      data: (rows) => rows.take(5).map((r) => RecentAttendance(
            date: (r['date'] ?? r['created_at'] ?? '').toString(),
            subject: (r['subject_name'] ?? r['subject'] ?? r['title'] ?? '').toString(),
            className: (r['class_name'] ?? r['program'] ?? '').toString(),
            type: (r['type'] ?? r['class_type'] ?? '').toString(),
            present: (r['present'] ?? r['present_count'] ?? r['present_summary'] ?? '').toString(),
          )).toList(),
      loading: () => <RecentAttendance>[],
      error: (_, __) => <RecentAttendance>[],
    );

    return AppScaffold(
      title: 'Attendance',
      subtitle: 'Operations',
      currentRoute: '/attendance',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _attendanceSection(context, students, enrollmentsAsync),
          const SizedBox(height: 20),
          _recentSessionsCard(context, recentSessions),
        ],
      ),
    );
  }

  List<StudentAttendance> _mapEnrollmentsToStudents(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final studentRaw = row['student'];
      final Map<dynamic, dynamic> student = (studentRaw is Map) ? studentRaw : row;
      final studentId = (student['id'] ?? row['student_id'] ?? 0) as int;
      final fullName = (student['full_name'] ?? student['name'] ?? student['student_name'] ?? 'Unknown Student').toString();
      final roll = (student['student_id_code'] ?? student['roll_no'] ?? student['roll_number'] ?? student['registration'] ?? '').toString();
      final initials = fullName.trim().isEmpty
          ? 'ST'
          : fullName.trim().split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join().toUpperCase();
      return StudentAttendance(
        id: studentId,
        initials: initials,
        name: fullName,
        rollNo: roll.isEmpty ? '-' : roll,
        status: AttendanceStatus.present,
      );
    }).toList();
  }

  Widget _attendanceSection(
    BuildContext context,
    List<StudentAttendance> students,
    AsyncValue<List<Map<String, dynamic>>> enrollmentsAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    final isTeacher = AppSession.currentRole.toLowerCase() == 'teacher';
    final teacherSubsAsync = ref.watch(teacherAssignedSubjectsProvider);
    final allSubjectsAsync = ref.watch(subjectsListProvider);
    final subjectsAsync = isTeacher
        ? (teacherSubsAsync.value != null && teacherSubsAsync.value!.isNotEmpty ? teacherSubsAsync : allSubjectsAsync)
        : allSubjectsAsync;

    final subjectsList = subjectsAsync.value ?? <SubjectApiModel>[];
    final Map<String, String> classMap = {};
    for (final s in subjectsList) {
      final progName = s.program?.name ?? 'Class';
      final stageName = s.stage > 0 ? 'Semester ${s.stage}' : 'Stage ${s.stage}';
      final key = '${s.program?.id ?? 0}_${s.stage}';
      classMap[key] = '$progName · $stageName';
    }

    final safeClassKey = classMap.containsKey(_selectedClassKey)
        ? _selectedClassKey
        : (classMap.isNotEmpty ? classMap.keys.first : null);

    final filteredSubjects = safeClassKey == null
        ? subjectsList
        : subjectsList.where((s) => '${s.program?.id ?? 0}_${s.stage}' == safeClassKey).toList();

    final safeSelectedSubjectId = filteredSubjects.any((s) => s.id == _selectedSubjectId)
        ? _selectedSubjectId
        : (filteredSubjects.isNotEmpty ? filteredSubjects.first.id : null);

    final selectedClassLabel = (safeClassKey != null && classMap.containsKey(safeClassKey))
        ? classMap[safeClassKey]!
        : 'Select Class / Semester';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mark Attendance', style: AppTextStyles.h2),
                          const SizedBox(height: 4),
                          Text(
                            'Select student status: Present (P), Absent (A), Late (L), or Sick (S)',
                            style: AppTextStyles.body.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Mark Class:',
                                  style: AppTextStyles.bodySm.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _classBulkButton(
                                  shortLabel: 'All Present',
                                  color: AppColors.success,
                                  onTap: () => _markAllStatus(students, AttendanceStatus.present),
                                ),
                                const SizedBox(width: 6),
                                _classBulkButton(
                                  shortLabel: 'All Absent',
                                  color: AppColors.danger,
                                  onTap: () => _markAllStatus(students, AttendanceStatus.absent),
                                ),
                                const SizedBox(width: 6),
                                _classBulkButton(
                                  shortLabel: 'All Late',
                                  color: AppColors.warning,
                                  onTap: () => _markAllStatus(students, AttendanceStatus.late),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : () => _saveAttendance(students),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_rounded, size: 16),
                            label: const Text('Save session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _mobilePickerRow(
                        context,
                        label: 'Class / Semester',
                        value: selectedClassLabel,
                        onTap: () => _showClassBottomSheet(context, classMap, subjectsList),
                      ),
                      const SizedBox(height: 8),
                      _mobilePickerRow(
                        context,
                        label: 'Subject',
                        value: selectedSubject.isEmpty ? 'Select Subject' : selectedSubject,
                        onTap: () => _showSubjectBottomSheet(context, filteredSubjects),
                      ),
                      const SizedBox(height: 8),
                      _mobilePickerRow(
                        context,
                        label: 'Class type',
                        value: selectedType,
                        onTap: () => _showTypeBottomSheet(context),
                      ),
                      const SizedBox(height: 8),
                      _mobilePickerRow(
                        context,
                        label: 'Session date',
                        value: _formatDisplayDate(_selectedDate),
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            BadgeChip(
                              label: 'P • ${_countFromList(students, AttendanceStatus.present)} / ${students.length}',
                              tone: BadgeTone.success,
                            ),
                            const SizedBox(width: 8),
                            BadgeChip(
                              label: 'A • ${_countFromList(students, AttendanceStatus.absent)}',
                              tone: BadgeTone.danger,
                            ),
                            const SizedBox(width: 8),
                            BadgeChip(
                              label: 'L • ${_countFromList(students, AttendanceStatus.late)}',
                              tone: BadgeTone.warning,
                            ),
                            const SizedBox(width: 8),
                            BadgeChip(
                              label: 'S • ${_countFromList(students, AttendanceStatus.sick)}',
                              tone: BadgeTone.purple,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mark Entire Class:',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _classBulkButton(
                                    shortLabel: 'All Present',
                                    color: AppColors.success,
                                    onTap: () => _markAllStatus(students, AttendanceStatus.present),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _classBulkButton(
                                    shortLabel: 'All Absent',
                                    color: AppColors.danger,
                                    onTap: () => _markAllStatus(students, AttendanceStatus.absent),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _classBulkButton(
                                    shortLabel: 'All Late',
                                    color: AppColors.warning,
                                    onTap: () => _markAllStatus(students, AttendanceStatus.late),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : () => _saveAttendance(students),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 14),
                        label: const Text('Save session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      // 1. CLASS / SEMESTER FILTER
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: safeClassKey,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'CLASS / SEMESTER',
                          ),
                          dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
                          items: classMap.entries.map((e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (newClassKey) {
                            if (newClassKey == null) return;
                            final matchingSubs = subjectsList.where((s) => '${s.program?.id ?? 0}_${s.stage}' == newClassKey).toList();
                            setState(() {
                              _selectedClassKey = newClassKey;
                              if (matchingSubs.isNotEmpty) {
                                _selectedSubjectId = matchingSubs.first.id;
                                selectedSubject = matchingSubs.first.name;
                              } else {
                                _selectedSubjectId = null;
                                selectedSubject = '';
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      // 2. SUBJECT FILTER
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          value: safeSelectedSubjectId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'SUBJECT',
                          ),
                          dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
                          items: filteredSubjects.map((s) => DropdownMenuItem<int>(
                            value: s.id,
                            child: Text(s.name, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final sub = filteredSubjects.firstWhere((s) => s.id == value);
                            setState(() {
                              _selectedSubjectId = value;
                              selectedSubject = sub.name;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      // 3. DATE
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: _dateController,
                              decoration: const InputDecoration(
                                labelText: 'DATE',
                                suffixIcon: Icon(Icons.calendar_today_rounded),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // 4. TYPE
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'TYPE',
                          ),
                          dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
                          items: const [
                            DropdownMenuItem(
                              value: 'Theory',
                              child: Text('Theory'),
                            ),
                            DropdownMenuItem(
                              value: 'Lab',
                              child: Text('Lab'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => selectedType = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Import CSV'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    BadgeChip(
                      label: 'P • ${_countFromList(students, AttendanceStatus.present)} / ${students.length}',
                      tone: BadgeTone.success,
                    ),
                    const SizedBox(width: 8),
                    BadgeChip(
                      label: 'A • ${_countFromList(students, AttendanceStatus.absent)}',
                      tone: BadgeTone.danger,
                    ),
                    const SizedBox(width: 8),
                    BadgeChip(
                      label: 'L • ${_countFromList(students, AttendanceStatus.late)}',
                      tone: BadgeTone.warning,
                    ),
                    const SizedBox(width: 8),
                    BadgeChip(
                      label: 'S • ${_countFromList(students, AttendanceStatus.sick)}',
                      tone: BadgeTone.purple,
                    ),
                    const Spacer(),
                    Text(
                      '${((_countFromList(students, AttendanceStatus.present) / (students.isEmpty ? 1 : students.length)) * 100).round()}% present',
                      style: AppTextStyles.bodySm.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (isTablet || isDesktop) const SizedBox.shrink(),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
          if (enrollmentsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No students enrolled in this subject.',
                  style: AppTextStyles.body.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ),
            )
          else if (isMobile)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _studentAttendanceMobileTile(students[index]);
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(22),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isDesktop ? 2.5 : 2.1,
                ),
                itemBuilder: (context, index) {
                  return _studentCard(students[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  int _countFromList(List<StudentAttendance> students, AttendanceStatus status) {
    return students.where((entry) => entry.status == status).length;
  }

  Widget _mobilePickerRow(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: AppTextStyles.labelSm.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentSessionsCard(BuildContext context, List<RecentAttendance> recentSessions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Sessions', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(
                  'Last 5 attendance records',
                  style: AppTextStyles.body.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
          if (isMobile)
            ...recentSessions.map((e) => _sessionMobileCard(context, e))
          else ...[
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
              ),
              child: Row(
                children: [
                  _header('DATE', 2),
                  _header('SUBJECT', 3),
                  _header('CLASS', 1.4),
                  _header('TYPE', 1.2),
                  _header('PRESENT', 1.8),
                  _header('STATUS', 1.4),
                ],
              ),
            ),
            ...recentSessions.map((e) => _sessionRow(context, e)),
          ],
        ],
      ),
    );
  }

  Widget _sessionMobileCard(BuildContext context, RecentAttendance entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.date,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const BadgeChip(
                label: 'Submitted',
                tone: BadgeTone.success,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(entry.subject, style: AppTextStyles.body),
          const SizedBox(height: 4),
          Text(
            '${entry.className} · ${entry.type} · ${entry.present}',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionRow(BuildContext context, RecentAttendance entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
      ),
      child: Row(
        children: [
          _cell(entry.date, 2),
          _cell(entry.subject, 3),
          _cell(entry.className, 1.4),
          _cell(entry.type, 1.2),
          _cell(entry.present, 1.8),
          const Expanded(
            flex: 14,
            child: BadgeChip(
              label: 'Submitted',
              tone: BadgeTone.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text, double flex) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _cell(String text, double flex) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(
        text,
        style: AppTextStyles.body,
      ),
    );
  }

  Widget _studentAttendanceMobileTile(StudentAttendance student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _statusColors(student.status);

    return GestureDetector(
      onLongPress: () {
        setState(() => student.status = AttendanceStatus.late);
      },
      child: Dismissible(
        key: ValueKey<String>(student.rollNo),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          setState(() {
            if (direction == DismissDirection.startToEnd) {
              student.status = AttendanceStatus.present;
            } else if (direction == DismissDirection.endToStart) {
              student.status = AttendanceStatus.absent;
            }
          });
          return false;
        },
        background: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.success.withValues(alpha: 0.2) : AppColors.successSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success, width: 1.4),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 32,
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.danger.withValues(alpha: 0.2) : AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger, width: 1.4),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.cancel_rounded,
            color: AppColors.danger,
            size: 32,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.background.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.foreground,
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      student.initials,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.foreground,
                          ),
                        ),
                        Text(
                          student.rollNo,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.foreground.withValues(alpha: .75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.spaceEvenly,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _statusAction(
                    icon: Icons.check_circle_outline,
                    label: 'Present',
                    selected: student.status == AttendanceStatus.present,
                    color: AppColors.success,
                    onTap: () => setState(() {
                      student.status = AttendanceStatus.present;
                    }),
                  ),
                  _statusAction(
                    icon: Icons.cancel_outlined,
                    label: 'Absent',
                    selected: student.status == AttendanceStatus.absent,
                    color: AppColors.danger,
                    onTap: () => setState(() {
                      student.status = AttendanceStatus.absent;
                    }),
                  ),
                  _statusAction(
                    icon: Icons.schedule_rounded,
                    label: 'Late',
                    selected: student.status == AttendanceStatus.late,
                    color: AppColors.warning,
                    onTap: () => setState(() {
                      student.status = AttendanceStatus.late;
                    }),
                  ),
                  _statusAction(
                    icon: Icons.healing_outlined,
                    label: 'Sick',
                    selected: student.status == AttendanceStatus.sick,
                    color: AppColors.purple,
                    onTap: () => setState(() {
                      student.status = AttendanceStatus.sick;
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusAction({
    required IconData icon,
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? color : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentCard(StudentAttendance student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _statusColors(student.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.foreground.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Avatar + Name & Roll + Current Status Badge
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  student.initials,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      student.name,
                      style: AppTextStyles.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.rollNo,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.foreground.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusToCode(student.status),
                  style: TextStyle(
                    color: colors.foreground,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          // Bottom Row: Direct Option Buttons: [ P ] [ A ] [ L ] [ S ]
          Row(
            children: [
              _statusChipButton(
                code: 'P',
                label: 'Present',
                status: AttendanceStatus.present,
                currentStatus: student.status,
                color: AppColors.success,
                onTap: () => setState(() => student.status = AttendanceStatus.present),
              ),
              const SizedBox(width: 6),
              _statusChipButton(
                code: 'A',
                label: 'Absent',
                status: AttendanceStatus.absent,
                currentStatus: student.status,
                color: AppColors.danger,
                onTap: () => setState(() => student.status = AttendanceStatus.absent),
              ),
              const SizedBox(width: 6),
              _statusChipButton(
                code: 'L',
                label: 'Late',
                status: AttendanceStatus.late,
                currentStatus: student.status,
                color: AppColors.warning,
                onTap: () => setState(() => student.status = AttendanceStatus.late),
              ),
              const SizedBox(width: 6),
              _statusChipButton(
                code: 'S',
                label: 'Sick',
                status: AttendanceStatus.sick,
                currentStatus: student.status,
                color: AppColors.purple,
                onTap: () => setState(() => student.status = AttendanceStatus.sick),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChipButton({
    required String code,
    required String label,
    required AttendanceStatus status,
    required AttendanceStatus currentStatus,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = currentStatus == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color : (isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.border),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            code,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showClassBottomSheet(BuildContext context, Map<String, String> classMap, List<SubjectApiModel> subjects) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class / Semester', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                ...classMap.entries.map((entry) {
                  final isSelected = entry.key == _selectedClassKey;
                  return ListTile(
                    title: Text(
                      entry.value,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.text),
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () {
                      final matchingSubs = subjects.where((s) => '${s.program?.id ?? 0}_${s.stage}' == entry.key).toList();
                      setState(() {
                        _selectedClassKey = entry.key;
                        if (matchingSubs.isNotEmpty) {
                          _selectedSubjectId = matchingSubs.first.id;
                          selectedSubject = matchingSubs.first.name;
                        } else {
                          _selectedSubjectId = null;
                          selectedSubject = '';
                        }
                      });
                      Navigator.of(sheetContext).pop();
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSubjectBottomSheet(BuildContext context, List<SubjectApiModel> subjects) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subject', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                if (subjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No subjects found for this class',
                      style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                    ),
                  )
                else
                  ...subjects.map((s) {
                    final isSelected = s.id == _selectedSubjectId;
                    return ListTile(
                      title: Text(
                        s.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.text),
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          selectedSubject = s.name;
                          _selectedSubjectId = s.id;
                        });
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTypeBottomSheet(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class type', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Theory'),
                  onTap: () {
                    setState(() => selectedType = 'Theory');
                    Navigator.of(sheetContext).pop();
                  },
                ),
                ListTile(
                  title: const Text('Lab'),
                  onTap: () {
                    setState(() => selectedType = 'Lab');
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ({Color foreground, Color background}) _statusColors(
    AttendanceStatus status,
  ) {
    switch (status) {
      case AttendanceStatus.present:
        return (
          foreground: AppColors.success,
          background: AppColors.success,
        );
      case AttendanceStatus.absent:
        return (
          foreground: AppColors.danger,
          background: AppColors.danger,
        );
      case AttendanceStatus.late:
        return (
          foreground: AppColors.warning,
          background: AppColors.warning,
        );
      case AttendanceStatus.sick:
        return (
          foreground: AppColors.purple,
          background: AppColors.purple,
        );
    }
  }
}

enum AttendanceStatus {
  present,
  absent,
  late,
  sick,
}

class StudentAttendance {
  final int id;
  final String initials;
  final String name;
  final String rollNo;
  AttendanceStatus status;

  StudentAttendance({
    required this.id,
    required this.initials,
    required this.name,
    required this.rollNo,
    required this.status,
  });
}

class RecentAttendance {
  final String date;
  final String subject;
  final String className;
  final String type;
  final String present;

  RecentAttendance({
    required this.date,
    required this.subject,
    required this.className,
    required this.type,
    required this.present,
  });
}
