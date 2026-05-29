import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.darkSurface,
              onSurface: Colors.white,
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

  void _markAllPresent(List<StudentAttendance> students) {
    setState(() {
      for (var s in students) {
        s.status = AttendanceStatus.present;
      }
    });
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
    final subjectsAsync = ref.watch(subjectsListProvider);
    final sessionsAsync = ref.watch(sessionsListProvider);

    // enrollments require a selected subject id
    final enrollmentsAsync = _selectedSubjectId != null
      ? ref.watch(subjectEnrollmentsProvider(SubjectEnrollmentsArgs(subjectId: _selectedSubjectId!, sessionId: _selectedSessionId)))
      : const AsyncValue.data(<Map<String, dynamic>>[]);

    final attendanceSessionsAsync = ref.watch(attendanceSessionsListProvider(AttendanceSessionsArgs(subjectId: _selectedSubjectId, sessionId: _selectedSessionId)));

    // initialize default selections when providers become available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedSubjectId == null && subjectsAsync is AsyncData) {
        final subjects = subjectsAsync.value;
        if (subjects != null && subjects.isNotEmpty) {
          setState(() {
            _selectedSubjectId = subjects.first.id;
            selectedSubject = subjects.first.name;
          });
        }
      }
      if (_selectedSessionId == null && sessionsAsync is AsyncData) {
        final sessions = sessionsAsync.value;
        if (sessions != null && sessions.isNotEmpty) {
          setState(() => _selectedSessionId = sessions.first.id);
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
          _attendanceSection(context, students),
          const SizedBox(height: 20),
          _recentSessionsCard(context, recentSessions),
        ],
      ),
    );
  }

  List<StudentAttendance> _mapEnrollmentsToStudents(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final student = (row['student'] is Map) ? row['student'] as Map<String, dynamic> : row;
      final studentId = (student['id'] ?? 0) as int;
      final fullName = (student['full_name'] ?? student['name'] ?? student['student_name'] ?? '') as String;
      final roll = (student['roll_no'] ?? student['roll_number'] ?? student['registration'] ?? '') as String;
      final initials = fullName.trim().isEmpty
          ? ''
          : fullName.trim().split(' ').map((s) => s.isEmpty ? '' : s[0]).take(2).join().toUpperCase();
      return StudentAttendance(
        id: studentId,
        initials: initials,
        name: fullName,
        rollNo: roll,
        status: AttendanceStatus.present,
      );
    }).toList();
  }

  Widget _attendanceSection(BuildContext context, List<StudentAttendance> students) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    final subjectsAsync = ref.watch(subjectsListProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
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
                            'Tap a student card to cycle Present → Absent → Late → Sick',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.darkTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile)
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _markAllPresent(students),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.darkBorder),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Mark all present'),
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
                        label: 'Subject',
                        value: selectedSubject,
                        onTap: () => _showSubjectBottomSheet(context),
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
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _markAllPresent(students),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.darkBorder),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Mark all present'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: subjectsAsync.when(
                          loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                          error: (_, __) => const Text('Error loading subjects'),
                          data: (subjects) {
                            final list = subjects ?? [];
                            return DropdownButtonFormField<int>(
                              value: _selectedSubjectId,
                              decoration: const InputDecoration(
                                labelText: 'SUBJECT',
                              ),
                              dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
                              items: list.map((s) => DropdownMenuItem<int>(
                                value: s.id,
                                child: Text(s.name),
                              )).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                final sub = list.firstWhere((s) => s.id == value);
                                setState(() {
                                  _selectedSubjectId = value;
                                  selectedSubject = sub.name;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
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
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'TYPE',
                          ),
                          dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
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
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Import CSV'),
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
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
                if (isTablet || isDesktop) const SizedBox.shrink(),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.darkBorder),
          if (isMobile)
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
                  crossAxisCount: isDesktop ? 4 : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isTablet ? 1.25 : 1.0,
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
    return Material(
      color: AppColors.darkSurfaceAlt,
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
                        color: AppColors.darkTextMuted,
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
    final isMobile = Responsive.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
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
                    color: AppColors.darkTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.darkBorder),
          if (isMobile)
            ...recentSessions.map(_sessionMobileCard)
          else ...[
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.darkSurfaceAlt,
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
            ...recentSessions.map(_sessionRow),
          ],
        ],
      ),
    );
  }

  Widget _sessionMobileCard(RecentAttendance entry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
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
              color: AppColors.darkTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionRow(RecentAttendance entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
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
            color: AppColors.successSoft,
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
            color: AppColors.dangerSoft,
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
              color: selected ? color : AppColors.darkTextMuted,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : AppColors.darkTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentCard(StudentAttendance student) {
    final colors = _statusColors(student.status);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          student.status = switch (student.status) {
            AttendanceStatus.present => AttendanceStatus.absent,
            AttendanceStatus.absent => AttendanceStatus.late,
            AttendanceStatus.late => AttendanceStatus.sick,
            AttendanceStatus.sick => AttendanceStatus.present,
          };
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.foreground,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
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
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    student.rollNo,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.foreground.withValues(alpha: .75),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSubjectBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final subjectsAsync = ref.read(subjectsListProvider);
        final subjects = subjectsAsync.maybeWhen(data: (v) => v, orElse: () => <dynamic>[]);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subject', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                ...subjects.map((s) {
                  final name = (s is Map) ? (s['name'] ?? '') : (s.name ?? '');
                  final id = (s is Map) ? (s['id'] ?? 0) : s.id;
                  return ListTile(
                    title: Text(name.toString()),
                    onTap: () {
                      setState(() {
                        selectedSubject = name.toString();
                        _selectedSubjectId = id is int ? id : int.tryParse(id.toString());
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
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

  Future<void> _showDateBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session date', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'DD/MM/YYYY',
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Done'),
                  ),
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
