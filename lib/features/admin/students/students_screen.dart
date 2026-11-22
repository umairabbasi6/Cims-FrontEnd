import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/mobile/student_card.dart';
import 'package:cims/features/admin/students/enroll_student_modal.dart';
import 'package:cims/features/admin/students/student_detail_modal.dart';
import 'package:cims/features/admin/students/student_filter_modal.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/core/utils/csv_export_helper.dart' as csv_helper;

class StudentsScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const StudentsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<StudentsScreen> createState() =>
      _StudentsScreenState();
}

class _StudentsScreenState
    extends ConsumerState<StudentsScreen> {
  String selectedTab = 'All Students';
  String selectedStatusFilter = 'All Status';
  final TextEditingController _searchCtrl = TextEditingController();

  bool get _isTeacher =>
      AppSession.currentRole.toLowerCase() == 'teacher';

  final tabs = [
    'All Students',
    'DPT',
    'BS MLT',
    'Radiology',
    'Nursing',
    'Alumni',
  ];

  static const List<Color> _avatarPalette = [
    AppColors.info,
    AppColors.primary,
    AppColors.purple,
    AppColors.warning,
    AppColors.success,
  ];

  Color _avatarColor(int index) =>
      _avatarPalette[index % _avatarPalette.length];

  String prettyStatus(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  List<StudentApiModel> _filteredForTab(
    List<StudentApiModel> all,
  ) {
    bool containsAny(
      String? hay,
      List<String> needles,
    ) {
      if (hay == null) return false;
      final h = hay.toLowerCase();
      return needles.any((n) => h.contains(n.toLowerCase()));
    }

    switch (selectedTab) {
      case 'Alumni':
        return all
            .where((s) => s.status == 'graduated')
            .toList();
      case 'DPT':
        return all
            .where(
              (s) => containsAny(
                s.program?.name,
                ['dpt', 'physical therapy'],
              ) ||
                  containsAny(
                    s.program?.code,
                    ['dpt'],
                  ),
            )
            .toList();
      case 'BS MLT':
        return all
            .where(
              (s) => containsAny(
                s.program?.name,
                ['mlt', 'lab', 'medical lab'],
              ) ||
                  containsAny(
                    s.program?.code,
                    ['mlt'],
                  ),
            )
            .toList();
      case 'Radiology':
        return all
            .where(
              (s) => containsAny(
                s.program?.name,
                ['radiology', 'rit'],
              ) ||
                  containsAny(
                    s.program?.code,
                    ['rit', 'rad'],
                  ),
            )
            .toList();
      case 'Nursing':
        return all
            .where(
              (s) => containsAny(
                s.program?.name,
                ['nursing', 'lhv', 'nurse'],
              ) ||
                  containsAny(
                    s.program?.code,
                    ['nm', 'nur'],
                  ),
            )
            .toList();
      default:
        return all;
    }
  }

  List<Student> _toRows(List<StudentApiModel> api) {
    return api
        .asMap()
        .entries
        .map(
          (e) => Student.fromApi(
            e.value,
            _avatarColor(e.key),
          ),
        )
        .toList();
  }
  @override
  Widget build(BuildContext context) {
    final bool isPhone = Responsive.isMobile(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = ref.watch(studentsListProvider);

    return AppScaffold(
      title: _isTeacher ? 'My students' : 'Student Management',
      subtitle: _isTeacher ? 'Roster' : 'People',
      currentRoute: '/students',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      body: studentsAsync.when(
        skipLoadingOnReload: true,
        data: (apiList) {
          // Apply tab filtering first
          final tabFiltered = _filteredForTab(apiList);

          // Apply status filter
          final statusFiltered = selectedStatusFilter == 'All Status'
              ? tabFiltered
              : tabFiltered.where((s) => s.status == selectedStatusFilter).toList();

          // Apply search filter
          final query = _searchCtrl.text.trim().toLowerCase();
          final finalList = query.isEmpty
              ? statusFiltered
              : statusFiltered.where((s) {
                  final hay = '${s.fullName} ${s.studentIdCode} ${s.phone ?? ''} ${s.email ?? ''} ${s.registrationNumber}'.toLowerCase();
                  return hay.contains(query);
                }).toList();

          // Sort by id descending so newly added students appear at the top
          final sortedList = List<StudentApiModel>.from(finalList)
            ..sort((a, b) => b.id.compareTo(a.id));

          final students = _toRows(sortedList);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tabs.map((tab) {
                  final active = selectedTab == tab;

                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      setState(() => selectedTab = tab);
                      if (tab == 'Alumni') {
                        ref.read(studentStatusFilterProvider.notifier).state = 'graduated';
                      } else {
                        ref.read(studentStatusFilterProvider.notifier).state = null;
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : (isDark ? Colors.transparent : Colors.white),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        boxShadow: active || isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Text(
                        tab,
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : (isDark ? AppColors.darkText : AppColors.text),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: isPhone
                          ? _mobileToolbar(finalList, isDark)
                          : _desktopToolbar(finalList, isDark),
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                    if (isPhone)
                      ...students.map(_studentCard)
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 1200,
                          child: Column(
                            children: [
                              Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                ),
                                child: Row(
                                  children: [
                                    _header('STUDENT', 2.5, isDark),
                                    _header('ROLL NO', 2.1, isDark),
                                    _header('PROGRAM', 3, isDark),
                                    _header('SESSION', 1.8, isDark),
                                    _header('STAGE', 1.2, isDark),
                                    _header('STATUS', 1.6, isDark),
                                    _header('ACTIONS', 1.8, isDark),
                                  ],
                                ),
                              ),
                              ...students.map((s) => _studentRow(s, isDark)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
        error:
            (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$err',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(
                        studentsListProvider,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _desktopToolbar(List<StudentApiModel> finalList, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search records',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 180,
          child: Builder(builder: (ctx) {
            // Build dropdown items dynamically from current students list
            final studentsAsync = ref.watch(studentsListProvider);
            final opts = <String>['All Status'];
            if (studentsAsync is AsyncData<List<StudentApiModel>>) {
              final set = <String>{};
              for (final s in studentsAsync.value) {
                set.add(s.status);
              }
              opts.addAll(set);
            }

            return DropdownButtonFormField<String>(
              initialValue: opts.contains(selectedStatusFilter) ? selectedStatusFilter : 'All Status',
              decoration: const InputDecoration(),
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
              items: opts.map((e) => DropdownMenuItem(value: e, child: Text(prettyStatus(e)))).toList(),
              onChanged: (v) => setState(() => selectedStatusFilter = v ?? 'All Status'),
            );
          }),
        ),
        const SizedBox(width: 14),
        _filterButton(isDark),
        const Spacer(),
        if (!_isTeacher) ...[
          OutlinedButton.icon(
            onPressed: () => _exportStudentsCsv(finalList),
            icon: Icon(Icons.download_rounded, color: isDark ? Colors.white : AppColors.text),
            label: Text('Export', style: TextStyle(color: isDark ? Colors.white : AppColors.text)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Batch Actions',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flash_on_rounded, size: 20),
            ),
            onSelected: (val) {
              if (val == 'promote') _showBulkPromoteDialog();
              if (val == 'graduate') _showBulkGraduateDialog();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'promote',
                child: Row(
                  children: [
                    Icon(Icons.upgrade_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Batch Promote Cohort'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'graduate',
                child: Row(
                  children: [
                    Icon(Icons.school_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Batch Graduate Eligible'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showEnrollModal,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Enroll Student'),
          ),
        ],
      ],
    );
  }

  void _showBulkPromoteDialog() {
    final sessionsAsync = ref.read(sessionsProvider);
    int? selectedSessionId;
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Batch Promote Students'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will advance all active students by 1 stage in the database engine using PostgreSQL stored procedures.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              sessionsAsync.when(
                data: (sess) => DropdownButtonFormField<int>(
                  value: selectedSessionId,
                  decoration: const InputDecoration(labelText: 'Target Session'),
                  items: sess.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (v) => setDlgState(() => selectedSessionId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading sessions: $e'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProcessing || selectedSessionId == null
                  ? null
                  : () async {
                      setDlgState(() => isProcessing = true);
                      try {
                        final msg = await ref.read(studentRepositoryProvider).bulkPromoteStudents(selectedSessionId!);
                        ref.invalidate(studentsListProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: AppColors.success),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setDlgState(() => isProcessing = false);
                      }
                    },
              child: Text(isProcessing ? 'Promoting...' : 'Promote Cohort'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkGraduateDialog() {
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Batch Graduate Eligible Students'),
          content: const Text(
            'This will graduate all active students who have reached or exceeded their program\'s total required stages. Are you sure you want to proceed?',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: isProcessing
                  ? null
                  : () async {
                      setDlgState(() => isProcessing = true);
                      try {
                        final msg = await ref.read(studentRepositoryProvider).bulkGraduateStudents();
                        ref.invalidate(studentsListProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: AppColors.success),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setDlgState(() => isProcessing = false);
                      }
                    },
              child: Text(isProcessing ? 'Graduating...' : 'Graduate Eligible'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportStudentsCsv(List<StudentApiModel> list) {
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No student records to export.')),
      );
      return;
    }

    final StringBuffer csv = StringBuffer();
    csv.writeln('ID,Roll No,Name,Email,Phone,Program,Session,Stage,Status');

    for (final s in list) {
      final name = s.fullName.replaceAll('"', '""');
      final roll = s.studentIdCode;
      final email = s.email ?? '';
      final phone = s.phone ?? '';
      final prog = s.program?.name ?? '';
      final sess = s.admissionSession?.name ?? '';
      final stage = 'Stage ${s.currentStage}';
      final status = s.status;

      csv.writeln('${s.id},"$roll","$name","$email","$phone","$prog","$sess","$stage","$status"');
    }

    final fileName = 'Students_Export_${DateTime.now().toLocal().toString().split(' ')[0]}.csv';
    csv_helper.saveAndShareCsv(
      csvString: csv.toString(),
      fileName: fileName,
    );
  }

  Widget _filterButton(bool isDark) {
    final hasActiveFilters = ref.watch(studentProgramFilterProvider) != null ||
        ref.watch(studentSessionFilterProvider) != null ||
        ref.watch(studentStatusFilterProvider) != null;

    final defaultColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return TextButton.icon(
      onPressed: _showFilterDialog,
      icon: Icon(
        Icons.filter_alt_outlined,
        color: hasActiveFilters ? AppColors.primary : defaultColor,
      ),
      label: Text(
        hasActiveFilters ? 'Filters (Active)' : 'Filters',
        style: TextStyle(
          color: hasActiveFilters ? AppColors.primary : defaultColor,
          fontWeight: hasActiveFilters ? FontWeight.bold : null,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showResponsiveModal(
      context: context,
      barrierColor: Colors.black54,
      child: const StudentFilterModal(),
    );
  }

  Widget _mobileToolbar(List<StudentApiModel> finalList, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            hintText: 'Search records',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedStatusFilter,
                decoration: const InputDecoration(),
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
                items: () {
                  final opts = <String>['All Status'];
                  final studentsAsync = ref.watch(studentsListProvider);
                  if (studentsAsync is AsyncData<List<StudentApiModel>>) {
                    final set = <String>{};
                    for (final s in studentsAsync.value) {
                      set.add(s.status);
                    }
                    opts.addAll(set);
                  }
                  return opts.map((e) => DropdownMenuItem(value: e, child: Text(prettyStatus(e)))).toList();
                }(),
                onChanged: (v) => setState(() => selectedStatusFilter = v ?? 'All Status'),
              ),
            ),
            const SizedBox(width: 12),
            _filterButton(isDark),
          ],
        ),
        if (!_isTeacher) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportStudentsCsv(finalList),
                  icon: Icon(Icons.download_rounded, color: isDark ? Colors.white : AppColors.text),
                  label: Text('Export', style: TextStyle(color: isDark ? Colors.white : AppColors.text)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showEnrollModal,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Enroll'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _studentCard(Student s) {
    final data = StudentCardData(
      initials: s.initials,
      name: s.name,
      rollNo: s.rollNo,
      program: s.program,
      session: s.session,
      stage: s.stage,
      status: s.status,
      avatarColor: s.avatarColor,
      studentId: s.originalModel.id,
    );

    return Builder(
      builder: (context) {
        final isPhone = Responsive.isMobile(context);
        return StudentCard(
          data: data,
          onTap: isPhone
              ? () => showStudentQuickDetailSheet(
                    context,
                    data,
                  )
              : null,
          showMenu: true,
          menuItems: _isTeacher
              ? (ctx) => const [
                    PopupMenuItem(
                      value: 'view',
                      child: Text('View'),
                    ),
                  ]
              : (ctx) => const [
                    PopupMenuItem(
                      value: 'view',
                      child: Text('View'),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
          onMenuSelected: (value) async {
            final repo = ref.read(studentRepositoryProvider);
            if (value == 'view') {
              if (isPhone) {
                showStudentQuickDetailSheet(context, data);
              } else {
                showResponsiveModal(context: context, barrierColor: Colors.black54, child: StudentDetailModal(studentId: data.studentId ?? 0));
              }
            } else if (value == 'edit') {
              // open edit modal by fetching model from repo
              final model = await repo.getStudent(data.studentId ?? 0);
              final updated = await showResponsiveModal<bool>(
                context: context,
                barrierColor: Colors.black54,
                child: EnrollStudentModal(studentToEdit: model),
              );
              if (updated == true) {
                ref.invalidate(studentsListProvider);
              }
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm delete'),
                  content: Text('Delete ${data.name}? This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirmed == true) {
                  try {
                  await repo.deleteStudent(data.studentId ?? 0);
                  ref.invalidate(studentsListProvider);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${data.name} deleted')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                }
              }
            }
          },
        );
      },
    );
  }

  Widget _studentRow(Student s, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.text;
    final textMutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 25,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: s.avatarColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.initials,
                    style: AppTextStyles.bodySm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.rollNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 21,
            child: Text(
              s.rollNo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 30,
            child: Text(
              s.program,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              s.session,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: BadgeChip(
              label: s.stage,
              tone: BadgeTone.primary,
            ),
          ),
          Expanded(
            flex: 16,
            child: BadgeChip.status(s.status),
          ),
          Expanded(
            flex: 18,
            child: _isTeacher
                ? Row(
                    children: [
                      _actionButton(Icons.visibility_outlined, () {
                        showResponsiveModal(
                          context: context,
                          barrierColor: Colors.black54,
                          child: StudentDetailModal(studentId: s.originalModel.id),
                        );
                      }, isDark),
                    ],
                  )
                : Row(
                    children: [
                      _actionButton(Icons.visibility_outlined, () {
                        showResponsiveModal(
                          context: context,
                          barrierColor: Colors.black54,
                          child: StudentDetailModal(studentId: s.originalModel.id),
                        );
                      }, isDark),
                      const SizedBox(width: 6),
                      _actionButton(Icons.edit_outlined, () async {
                        final updated = await showResponsiveModal<bool>(
                          context: context,
                          barrierColor: Colors.black54,
                          child: EnrollStudentModal(studentToEdit: s.originalModel),
                        );
                        if (updated == true) {
                          ref.invalidate(studentsListProvider);
                        }
                      }, isDark),
                      const SizedBox(width: 6),
                      _actionButton(Icons.delete_outline_rounded, () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm delete'),
                            content: Text('Delete ${s.name}? This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          try {
                            final repo = ref.read(studentRepositoryProvider);
                            await repo.deleteStudent(s.originalModel.id);
                            ref.invalidate(studentsListProvider);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s.name} deleted')));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                          }
                        }
                      }, isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text, double flex, bool isDark) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 13,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
      ),
    );
  }

  void _showEnrollModal() {
    showResponsiveModal(
      context: context,
      barrierColor: Colors.black54,
      child: const EnrollStudentModal(),
    );
  }
}

class Student {
  final String initials;
  final String name;
  final String rollNo;
  final String program;
  final String session;
  final String stage;
  final String status;
  final Color avatarColor;
  final StudentApiModel originalModel;

  Student({
    required this.initials,
    required this.name,
    required this.rollNo,
    required this.program,
    required this.session,
    required this.stage,
    required this.status,
    required this.avatarColor,
    required this.originalModel,
  });

  factory Student.fromApi(
    StudentApiModel s,
    Color avatarColor,
  ) {
    final parts =
        s.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .toList();
    String initials;
    if (parts.isEmpty) {
      initials = '?';
    } else if (parts.length == 1) {
      final t = parts.first;
      initials =
          t.length >= 2
              ? t.substring(0, 2).toUpperCase()
              : t.toUpperCase();
    } else {
      initials =
          (parts.first[0] + parts.last[0])
              .toUpperCase();
    }

    String prettyStatus(String raw) {
      if (raw.isEmpty) return raw;
      return raw
          .split('_')
          .map(
            (w) => w.isEmpty
                ? w
                : '${w[0].toUpperCase()}${w.substring(1)}',
          )
          .join(' ');
    }

    return Student(
      initials: initials,
      name: s.fullName,
      rollNo: s.studentIdCode,
      program: s.program?.name ?? '—',
      session: s.admissionSession?.name ?? '—',
      stage: 'Stage ${s.currentStage}',
      status: prettyStatus(s.status),
      avatarColor: avatarColor,
      originalModel: s,
    );
  }
}
