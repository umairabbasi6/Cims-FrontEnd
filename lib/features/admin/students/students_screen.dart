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

          final students = _toRows(finalList);

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
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : AppColors.darkBorder,
                        ),
                      ),
                      child: Text(
                        tab,
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : AppColors.darkText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.darkBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: isPhone
                          ? _mobileToolbar()
                          : _desktopToolbar(),
                    ),
                    Divider(
                      height: 1,
                      color: AppColors.darkBorder,
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
                                decoration: const BoxDecoration(
                                  color: AppColors.darkSurfaceAlt,
                                ),
                                child: Row(
                                  children: [
                                    _header('STUDENT', 2.5),
                                    _header('ROLL NO', 2.1),
                                    _header('PROGRAM', 3),
                                    _header('SESSION', 1.8),
                                    _header('STAGE', 1.2),
                                    _header('STATUS', 1.6),
                                    _header('ACTIONS', 1.8),
                                  ],
                                ),
                              ),
                              ...students.map(_studentRow),
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

  Widget _desktopToolbar() {
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
        SizedBox(width: 12),
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
              dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
              items: opts.map((e) => DropdownMenuItem(value: e, child: Text(prettyStatus(e)))).toList(),
              onChanged: (v) => setState(() => selectedStatusFilter = v ?? 'All Status'),
            );
          }),
        ),
        SizedBox(width: 14),
        _filterButton(),
        const Spacer(),
        if (!_isTeacher) ...[
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export'),
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showEnrollModal,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Enroll Student'),
          ),
        ],
      ],
    );
  }

  Widget _filterButton() {
    final hasActiveFilters = ref.watch(studentProgramFilterProvider) != null ||
        ref.watch(studentSessionFilterProvider) != null ||
        ref.watch(studentStatusFilterProvider) != null;

    return TextButton.icon(
      onPressed: _showFilterDialog,
      icon: Icon(
        Icons.filter_alt_outlined,
        color: hasActiveFilters ? AppColors.primary : null,
      ),
      label: Text(
        hasActiveFilters ? 'Filters (Active)' : 'Filters',
        style: TextStyle(
          color: hasActiveFilters ? AppColors.primary : null,
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

  Widget _mobileToolbar() {
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
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedStatusFilter,
                decoration: const InputDecoration(),
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
            SizedBox(width: 12),
            _filterButton(),
          ],
        ),
        if (!_isTeacher) ...[
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export'),
                ),
              ),
              SizedBox(width: 12),
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

  Widget _studentRow(Student s) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.darkBorder,
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
                SizedBox(width: 12),
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
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        s.rollNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.darkTextMuted,
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
              ),
            ),
          ),
          Expanded(
            flex: 30,
            child: Text(
              s.program,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              s.session,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
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
                              }),
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
                      }),
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
                      }),
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
                      }),
                    ],
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
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.darkBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.darkTextMuted,
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
