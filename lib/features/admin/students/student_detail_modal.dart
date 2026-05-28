import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/features/admin/students/enroll_student_modal.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/students/repository/student_repository.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/programs/providers/program_provider.dart';
import 'package:cims/features/admin/programs/models/program_stage_model.dart';
import 'package:cims/features/admin/enrollments/providers/enrollment_provider.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';
import 'package:dio/dio.dart';
import 'package:cims/core/network/dio_error_message.dart';
import 'package:cims/core/widgets/badge_chip.dart';

class StudentDetailModal extends ConsumerStatefulWidget {
  final int studentId;

  const StudentDetailModal({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailModal> createState() => _StudentDetailModalState();
}

class _StudentDetailModalState extends ConsumerState<StudentDetailModal> {
  int _refreshTrigger = 0;

  void _refresh() {
    setState(() {
      _refreshTrigger++;
    });
    ref.invalidate(studentsListProvider);
  }

  bool get _isAdmin => AppSession.currentRole.toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionsListProvider); // Pre-warm sessions list
    final repo = ref.read(studentRepositoryProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: Responsive.modalInsetPadding(context),
      child: Container(
        width: Responsive.modalWidth(context),
        constraints: const BoxConstraints(maxWidth: 750),
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: FutureBuilder<StudentApiModel>(
          // ignore: unused_local_parameter
          future: repo.getStudent(widget.studentId),
          key: ValueKey(_refreshTrigger),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load student: ${snap.error}', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }

            final s = snap.data!;

            return DefaultTabController(
              length: _isAdmin ? 4 : 2,
              child: Column(
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.fullName, style: AppTextStyles.h2),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    s.studentIdCode,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.darkTextMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: s.isActive 
                                        ? AppColors.success.withValues(alpha: 0.15)
                                        : AppColors.danger.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: s.isActive 
                                          ? AppColors.success.withValues(alpha: 0.3)
                                          : AppColors.danger.withValues(alpha: 0.3)
                                      ),
                                    ),
                                    child: Text(
                                      s.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: s.isActive ? AppColors.success : AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: AppColors.darkBorder, height: 1),
                  
                  // TABS BAR
                  TabBar(
                    indicatorColor: AppColors.primary,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.darkTextMuted,
                    labelStyle: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold),
                    tabs: [
                      const Tab(text: 'Details'),
                      const Tab(text: 'Academic History'),
                      if (_isAdmin) const Tab(text: 'Subject Enrollments'),
                      if (_isAdmin) const Tab(text: 'Actions'),
                    ],
                  ),
                  Divider(color: AppColors.darkBorder, height: 1),

                  // TAB VIEWS
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDetailsTab(s),
                        _buildHistoryTab(repo, s.id),
                        if (_isAdmin) _buildEnrollmentsTab(s),
                        if (_isAdmin) _buildActionsTab(s),
                      ],
                    ),
                  ),

                  // FOOTER
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceAlt,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(color: AppColors.darkBorder),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_isAdmin) ...[
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final updated = await showResponsiveModal<bool>(
                                context: context,
                                barrierColor: Colors.black54,
                                child: EnrollStudentModal(studentToEdit: s),
                              );
                              if (updated == true) {
                                ref.invalidate(studentsListProvider);
                              }
                            },
                            child: const Text('Edit Student info'),
                          ),
                          const SizedBox(width: 12),
                        ],
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailsTab(StudentApiModel s) {
    Widget row(String label, String? value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.darkTextMuted,
                ),
              ),
            ),
            Expanded(
              child: Text(value ?? '—', style: AppTextStyles.body),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('Registration Number', s.registrationNumber),
          row('First Name', s.firstName),
          row('Last Name', s.lastName),
          row('Email', s.email),
          row('Phone', s.phone),
          row('Date of Birth', s.dateOfBirth),
          row('Address', s.address),
          row('Guardian Name', s.guardianName),
          row('Guardian Phone', s.guardianPhone),
          row('Program', s.program?.name),
          row('Admission Session', s.admissionSession?.name),
          row('Current Stage', 'Stage ${s.currentStage}'),
          row('Graduation Date', s.graduationDate),
          row('Created At', DateFormat('MMM dd, yyyy HH:mm').format(s.createdAt)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(StudentRepository repo, int id) {
    return FutureBuilder<StudentHistoryResponse>(
      future: repo.getStudentHistory(id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Text(
              'No history log available: ${snap.error ?? "No data"}',
              style: TextStyle(color: AppColors.darkTextMuted),
            ),
          );
        }

        final history = snap.data!.history;
        if (history.isEmpty) {
          return Center(
            child: Text(
              'No history records found for this student.',
              style: TextStyle(color: AppColors.darkTextMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(item.createdAt);
            
            // Format nice title based on status
            final title = item.status[0].toUpperCase() + item.status.substring(1);

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (index != history.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.darkBorder,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 10),
                              Text(
                                dateStr, 
                                style: AppTextStyles.caption.copyWith(color: AppColors.darkTextMuted)
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Session: ${item.session?.name ?? "N/A"}  |  Stage: ${item.stage}', 
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)
                          ),
                          if (item.remarks.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.remarks,
                              style: AppTextStyles.bodySm.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.darkTextMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionsTab(StudentApiModel s) {
    if (s.program != null) {
      ref.watch(programStagesProvider(s.program!.id)); // Pre-warm program stages
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Lifecycle Management', 
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: Colors.white)
          ),
          const SizedBox(height: 6),
          Text(
            'Change status, promote stages, freeze semesters, or strike off.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.darkTextMuted),
          ),
          const SizedBox(height: 24),

          // PROMOTE
          if (s.status == 'active') ...[
            _actionCard(
              title: 'Promote Student',
              desc: s.currentStage >= (s.program?.totalStages ?? 0)
                  ? 'Student is at the maximum stage (${s.program?.totalStages}). They should be graduated instead.'
                  : 'Move student to the next semester or stage of their program.',
              icon: Icons.trending_up_rounded,
              color: s.currentStage >= (s.program?.totalStages ?? 0)
                  ? AppColors.darkTextMuted
                  : AppColors.success,
              onPressed: s.currentStage >= (s.program?.totalStages ?? 0)
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot promote: Student is already at the maximum stage. Use the Graduate action instead.')),
                      );
                    }
                  : () => _showLifecycleDialog(
                      title: 'Promote Student',
                      student: s,
                      onSubmit: (sessionId, remarks, date) async {
                        await ref.read(studentRepositoryProvider).promoteStudent(
                          s.id,
                          sessionId: sessionId,
                          remarks: remarks,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],

          // FREEZE
          if (s.status == 'active') ...[
            _actionCard(
              title: 'Freeze Semester (Leave)',
              desc: 'Put student enrollment on hold for gap semesters or medical leaves.',
              icon: Icons.pause_circle_outline_rounded,
              color: AppColors.warning,
              onPressed: () => _showLifecycleDialog(
                title: 'Freeze Semester',
                student: s,
                onSubmit: (sessionId, remarks, date) async {
                  await ref.read(studentRepositoryProvider).freezeStudent(
                    s.id,
                    sessionId: sessionId,
                    remarks: remarks,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // GRADUATE
          if (s.status == 'active') ...[
            _actionCard(
              title: 'Graduate Student',
              desc: 'Mark student as alumni upon successful completion of program stages.',
              icon: Icons.school_rounded,
              color: AppColors.primary,
              onPressed: () => _showLifecycleDialog(
                title: 'Graduate Student',
                student: s,
                includeDate: true,
                onSubmit: (sessionId, remarks, date) async {
                  await ref.read(studentRepositoryProvider).graduateStudent(
                    s.id,
                    sessionId: sessionId,
                    graduationDate: date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    remarks: remarks,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // STRIKE OFF
          if (s.status == 'active') ...[
            _actionCard(
              title: 'Strike Off Student',
              desc: 'Dismiss student from the college (serious disciplinary or defaults).',
              icon: Icons.gavel_rounded,
              color: AppColors.danger,
              onPressed: () => _showLifecycleDialog(
                title: 'Strike Off Student',
                student: s,
                onSubmit: (sessionId, remarks, date) async {
                  await ref.read(studentRepositoryProvider).strikeOffStudent(
                    s.id,
                    sessionId: sessionId,
                    remarks: remarks,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // RESTORE
          if (s.status == 'struck_off' || s.status == 'on_leave' || s.status == 'frozen' || s.status == 'suspended') ...[
            _actionCard(
              title: 'Restore Student',
              desc: 'Re-activate a frozen, on-leave, or struck-off student back to Active status.',
              icon: Icons.restore_rounded,
              color: AppColors.info,
              onPressed: () => _showLifecycleDialog(
                title: 'Restore Student',
                student: s,
                onSubmit: (sessionId, remarks, date) async {
                  await ref.read(studentRepositoryProvider).restoreStudent(
                    s.id,
                    sessionId: sessionId,
                    remarks: remarks,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(desc, style: AppTextStyles.caption.copyWith(color: AppColors.darkTextMuted)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: onPressed,
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsTab(StudentApiModel s) {
    final enrollmentsAsync = ref.watch(studentEnrollmentsProvider(
      StudentEnrollmentsArgs(studentId: s.id),
    ));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject Enrollments',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage ongoing and repeat subjects',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showBulkEnrollDialog(s),
                icon: const Icon(Icons.group_add_rounded, size: 16),
                label: const Text('Bulk Enroll'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showSingleEnrollDialog(s),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Enroll'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: enrollmentsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No subject enrollments found.',
                      style: TextStyle(color: AppColors.darkTextMuted),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final e = list[index];
                    final subject = e['subject'] as Map<String, dynamic>? ?? {};
                    final session = e['session'] as Map<String, dynamic>? ?? {};
                    final subjectName = subject['name']?.toString() ?? 'Unknown Subject';
                    final subjectCode = subject['code']?.toString() ?? '—';
                    final sessionName = session['name']?.toString() ?? '—';
                    final attempt = e['attempt_number'] ?? 1;
                    final statusStr = e['status']?.toString() ?? 'ongoing';
                    final enrollmentId = e['id'] as int;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subjectName,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$subjectCode · Session: $sessionName · Attempt #$attempt',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.darkTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          BadgeChip.status(statusStr),
                          const SizedBox(width: 12),
                          _buildEnrollmentActionsMenu(enrollmentId, s, subject, session, statusStr),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentActionsMenu(
    int enrollmentId,
    StudentApiModel student,
    Map<String, dynamic> subject,
    Map<String, dynamic> session,
    String currentStatus,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      color: AppColors.darkSurface,
      onSelected: (action) {
        if (action == 'status') {
          _showStatusUpdateDialog(enrollmentId, student, currentStatus);
        } else if (action == 'drop') {
          _confirmDropEnrollment(enrollmentId, student);
        } else if (action == 'repeat') {
          _confirmRepeatEnrollment(student, subject, session);
        } else if (action == 'delete') {
          _confirmDeleteEnrollment(enrollmentId, student);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 16),
              SizedBox(width: 8),
              Text('Update Status'),
            ],
          ),
        ),
        if (currentStatus == 'ongoing')
          const PopupMenuItem(
            value: 'drop',
            child: Row(
              children: [
                Icon(Icons.close_rounded, size: 16, color: AppColors.warning),
                SizedBox(width: 8),
                Text('Drop Course'),
              ],
            ),
          ),
        if (currentStatus == 'completed' || currentStatus == 'failed' || currentStatus == 'absent')
          const PopupMenuItem(
            value: 'repeat',
            child: Row(
              children: [
                Icon(Icons.replay_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Repeat Course'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Delete Record'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showSingleEnrollDialog(StudentApiModel student) async {
    int? selectedSubId;
    int? selectedSessId;
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, child) {
                final subjectsAsync = ref.watch(subjectsListProvider);
                final sessionsAsync = ref.watch(sessionsListProvider);

                final subjects = subjectsAsync.value ?? [];
                final sessions = sessionsAsync.value ?? [];

                if (selectedSessId == null && sessions.isNotEmpty) {
                  selectedSessId = sessions.first.id;
                }
                if (selectedSubId == null && subjects.isNotEmpty) {
                  selectedSubId = subjects.first.id;
                }

                return AlertDialog(
                  backgroundColor: AppColors.darkSurface,
                  title: const Text('Enroll in Subject', style: TextStyle(color: Colors.white)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Academic Session', style: TextStyle(color: AppColors.darkTextMuted)),
                      const SizedBox(height: 6),
                      sessionsAsync.when(
                        data: (list) => DropdownButtonFormField<int>(
                          value: selectedSessId,
                          dropdownColor: AppColors.darkSurface,
                          items: list.map((s) => DropdownMenuItem<int>(
                            value: s.id,
                            child: Text(s.name),
                          )).toList(),
                          onChanged: (v) => setState(() => selectedSessId = v),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Subject', style: TextStyle(color: AppColors.darkTextMuted)),
                      const SizedBox(height: 6),
                      subjectsAsync.when(
                        data: (list) => DropdownButtonFormField<int>(
                          value: selectedSubId,
                          dropdownColor: AppColors.darkSurface,
                          items: list.map((s) => DropdownMenuItem<int>(
                            value: s.id,
                            child: Text('${s.name} (${s.code})'),
                          )).toList(),
                          onChanged: (v) => setState(() => selectedSubId = v),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: loading ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: loading ? null : () async {
                        if (selectedSubId == null || selectedSessId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select both session and subject')),
                          );
                          return;
                        }

                        setState(() => loading = true);
                        try {
                           final repo = ref.read(enrollmentRepositoryProvider);
                           await repo.enrollSingle({
                             'student_id': student.id,
                             'subject_id': selectedSubId,
                             'session_id': selectedSessId,
                           });
                           ref.invalidate(studentEnrollmentsProvider(StudentEnrollmentsArgs(studentId: student.id)));
                           if (context.mounted) {
                             Navigator.pop(ctx);
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Student successfully enrolled!')),
                             );
                           }
                        } on DioException catch (e) {
                          final msg = dioErrorMessage(e, fallback: 'Enrollment failed');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                      child: loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Enroll'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showBulkEnrollDialog(StudentApiModel student) async {
    int? selectedSessId;
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, child) {
                final sessionsAsync = ref.watch(sessionsListProvider);
                final sessions = sessionsAsync.value ?? [];

                if (selectedSessId == null && sessions.isNotEmpty) {
                  selectedSessId = sessions.first.id;
                }

                return AlertDialog(
                  backgroundColor: AppColors.darkSurface,
                  title: const Text('Bulk Enrollment', style: TextStyle(color: Colors.white)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This will enroll ALL students at Stage ${student.currentStage} under "${student.program?.name ?? 'their program'}" in all of their stage subjects.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Target Session', style: TextStyle(color: AppColors.darkTextMuted)),
                      const SizedBox(height: 6),
                      sessionsAsync.when(
                        data: (list) => DropdownButtonFormField<int>(
                          value: selectedSessId,
                          dropdownColor: AppColors.darkSurface,
                          items: list.map((s) => DropdownMenuItem<int>(
                            value: s.id,
                            child: Text(s.name),
                          )).toList(),
                           onChanged: (v) => setState(() => selectedSessId = v),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: loading ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: loading ? null : () async {
                        if (selectedSessId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select session')),
                          );
                          return;
                        }

                        setState(() => loading = true);
                        try {
                           final repo = ref.read(enrollmentRepositoryProvider);
                           final res = await repo.bulkEnroll({
                             'program_id': student.program?.id,
                             'stage': student.currentStage,
                             'session_id': selectedSessId,
                           });
                           ref.invalidate(studentEnrollmentsProvider(StudentEnrollmentsArgs(studentId: student.id)));
                           if (context.mounted) {
                             Navigator.pop(ctx);
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('Bulk Enrollment Done! Enrolled: ${res['enrolled']}')),
                             );
                           }
                        } on DioException catch (e) {
                          final msg = dioErrorMessage(e, fallback: 'Bulk enrollment failed');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                      child: loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Enroll All'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showStatusUpdateDialog(int enrollmentId, StudentApiModel student, String currentStatus) async {
    String selectedStatus = currentStatus;
    final remarkCtrl = TextEditingController();
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, child) {
                final statusAsync = ref.watch(enrollmentStatusOptionsProvider);
                final options = statusAsync.value ?? ['ongoing', 'completed', 'failed', 'dropped', 'absent', 'suspended', 'canceled'];

                if (!options.contains(selectedStatus)) {
                  selectedStatus = options.first;
                }

                return AlertDialog(
                  backgroundColor: AppColors.darkSurface,
                  title: const Text('Update Subject Status', style: TextStyle(color: Colors.white)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status', style: TextStyle(color: AppColors.darkTextMuted)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        dropdownColor: AppColors.darkSurface,
                        items: options.map((opt) => DropdownMenuItem<String>(
                          value: opt,
                          child: Text(opt.toUpperCase()),
                        )).toList(),
                        onChanged: (v) => setState(() => selectedStatus = v ?? currentStatus),
                      ),
                      const SizedBox(height: 16),
                      const Text('Remarks / Notes', style: TextStyle(color: AppColors.darkTextMuted)),
                      const SizedBox(height: 6),
                      TextField(
                         controller: remarkCtrl,
                         decoration: const InputDecoration(hintText: 'Enter reason or grade...'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: loading ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: loading ? null : () async {
                        setState(() => loading = true);
                        try {
                           final repo = ref.read(enrollmentRepositoryProvider);
                           await repo.updateEnrollmentStatus(
                             enrollmentId,
                             status: selectedStatus,
                             remarks: remarkCtrl.text.trim(),
                           );
                           ref.invalidate(studentEnrollmentsProvider(StudentEnrollmentsArgs(studentId: student.id)));
                           if (context.mounted) {
                             Navigator.pop(ctx);
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Status updated successfully!')),
                             );
                           }
                        } on DioException catch (e) {
                          final msg = dioErrorMessage(e, fallback: 'Update failed');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                      child: loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Update'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDropEnrollment(int enrollmentId, StudentApiModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Drop Subject'),
        content: const Text('Are you sure you want to drop this subject? Status will be updated to DROPPED.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Drop'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final repo = ref.read(enrollmentRepositoryProvider);
      await repo.dropEnrollment(enrollmentId);
      ref.invalidate(studentEnrollmentsProvider(StudentEnrollmentsArgs(studentId: student.id)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject dropped successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drop failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmRepeatEnrollment(
    StudentApiModel student,
    Map<String, dynamic> subject,
    Map<String, dynamic> session,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Repeat Subject'),
        content: Text('Are you sure you want to repeat "${subject['name']}"? This will create a new enrollment record for session "${session['name']}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Repeat'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final repo = ref.read(enrollmentRepositoryProvider);
      await repo.repeatEnrollment({
        'student_id': student.id,
        'subject_id': subject['id'],
        'session_id': session['id'],
      });
      ref.invalidate(studentEnrollmentsProvider(StudentEnrollmentsArgs(studentId: student.id)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repeat enrollment created successfully.')),
        );
      }
    } on DioException catch (e) {
      final msg = dioErrorMessage(e, fallback: 'Repeat failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteEnrollment(int enrollmentId, StudentApiModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Enrollment'),
        content: const Text('Are you sure you want to delete this enrollment record? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final repo = ref.read(enrollmentRepositoryProvider);
      await repo.deleteEnrollment(enrollmentId);
      ref.invalidate(studentEnrollmentsProvider(StudentEnrollmentsArgs(studentId: student.id)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment record deleted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _showLifecycleDialog({
    required String title,
    required StudentApiModel student,
    bool includeDate = false,
    required Future<void> Function(int sessionId, String remarks, String? date) onSubmit,
  }) async {
    final remarkCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    
    int? selectedSessionId;
    bool loading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Consumer(
              builder: (context, ref, child) {
                final sessionsAsync = ref.watch(sessionsListProvider);

                AsyncValue<List<ProgramStage>>? stagesAsync;
                if (title == 'Promote Student' && student.program != null) {
                  stagesAsync = ref.watch(programStagesProvider(student.program!.id));
                }

                String targetStageLabel = 'Stage ${student.currentStage + 1}';
                if (stagesAsync != null) {
                  stagesAsync.whenData((stages) {
                    for (final stg in stages) {
                      if (stg.stage == student.currentStage + 1) {
                        targetStageLabel = stg.label;
                        break;
                      }
                    }
                  });
                }

                return AlertDialog(
                  backgroundColor: AppColors.darkSurface,
                  title: Text(title, style: AppTextStyles.h2),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title == 'Promote Student') ...[
                          Text('Promote to Stage / Semester', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: student.currentStage + 1,
                            decoration: const InputDecoration(
                              enabled: false,
                            ),
                            items: [
                              DropdownMenuItem<int>(
                                value: student.currentStage + 1,
                                child: Text(targetStageLabel),
                              ),
                            ],
                            onChanged: null,
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text('Select Academic Term / Session', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        sessionsAsync.when(
                          data: (list) {
                            if (list.isNotEmpty && selectedSessionId == null) {
                              selectedSessionId = list.first.id;
                            }
                            return DropdownButtonFormField<int>(
                              initialValue: selectedSessionId,
                              dropdownColor: AppColors.darkSurface,
                              items: list.map((e) => DropdownMenuItem<int>(
                                value: e.id,
                                child: Text(e.name),
                              )).toList(),
                              onChanged: (v) => setDialogState(() => selectedSessionId = v),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (err, _) => const Text('Error loading sessions', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(height: 20),

                        if (includeDate) ...[
                          Text('Date of graduation (yyyy-mm-dd)', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          TextField(
                            controller: dateCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'yyyy-mm-dd',
                              suffixIcon: Icon(Icons.calendar_today_rounded),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  dateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}';
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        Text('Remarks', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        TextField(
                          controller: remarkCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(hintText: 'Type remarks...'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: loading 
                        ? null 
                        : () async {
                            if (selectedSessionId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Session is required')),
                              );
                              return;
                            }
                            if (remarkCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Remarks are required')),
                              );
                              return;
                            }

                            setDialogState(() => loading = true);

                            try {
                              await onSubmit(
                                selectedSessionId!,
                                remarkCtrl.text.trim(),
                                includeDate ? dateCtrl.text.trim() : null,
                              );
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Student status successfully updated.')),
                                );
                                _refresh();
                              }
                            } on DioException catch (e) {
                              final msg = dioErrorMessage(e, fallback: 'Action failed');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $msg')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            } finally {
                              setDialogState(() => loading = false);
                            }
                          },
                      child: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}