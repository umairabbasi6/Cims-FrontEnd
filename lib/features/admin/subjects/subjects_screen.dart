import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/network/dio_error_message.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/modal_sheet.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/features/admin/subjects/models/subject_api_model.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';
import 'package:cims/features/admin/programs/providers/program_provider.dart';
import 'package:cims/features/admin/programs/models/program_model.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/core/utils/csv_export_helper.dart' as csv_helper;

class SubjectModel {
  final int id;
  final String name;
  final String meta;
  final String code;
  final String program;
  final String stage;
  final int credits;
  final bool practical;
  final String teacher;
  final int programId;
  final int stageNum;
  final SubjectApiModel apiModel;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.meta,
    required this.code,
    required this.program,
    required this.stage,
    required this.credits,
    required this.practical,
    required this.teacher,
    required this.programId,
    required this.stageNum,
    required this.apiModel,
  });

  factory SubjectModel.fromApi(SubjectApiModel api, {ProgramModel? program}) {
    final programName = api.program?.name ?? '—';
    final programCode = api.program?.code ?? '';

    final String stageLabel;
    if (program != null) {
      if (program.programType == 'Annual') {
        stageLabel = 'Year ${api.stage}';
      } else if (program.programType == 'Diploma') {
        stageLabel = 'Term ${api.stage}';
      } else {
        stageLabel = 'Semester ${api.stage}';
      }
    } else {
      stageLabel = 'Stage ${api.stage}';
    }

    final meta = programCode.isNotEmpty
        ? '$programCode · $stageLabel'
        : '$programName · $stageLabel';

    return SubjectModel(
      id: api.id,
      name: api.name,
      meta: meta,
      code: api.code,
      program: programName,
      stage: stageLabel,
      credits: api.creditHours.round(),
      practical: api.hasPractical,
      teacher: api.assignedTeacher?.fullName ?? '—',
      programId: api.program?.id ?? 0,
      stageNum: api.stage,
      apiModel: api,
    );
  }
}

class SubjectsScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const SubjectsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<SubjectsScreen> createState() =>
      _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'All Status';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SubjectModel> _filteredFromApi(
    List<SubjectApiModel> apiList,
    List<ProgramModel>? programs,
  ) {
    final subjects = apiList.map((api) {
      final matches = programs?.where((p) => p.id == api.program?.id);
      final prog = (matches != null && matches.isNotEmpty) ? matches.first : null;
      return SubjectModel.fromApi(api, program: prog);
    }).toList();

    return subjects.where((subject) {
      if (_statusFilter == 'Practical Only' && !subject.practical) {
        return false;
      }
      if (_statusFilter == 'Theory Only' && subject.practical) {
        return false;
      }
      if (_search.isEmpty) {
        return true;
      }

      final query = _search.toLowerCase();
      return subject.name.toLowerCase().contains(query) ||
          subject.code.toLowerCase().contains(query) ||
          subject.teacher.toLowerCase().contains(query);
    }).toList();
  }

  void _viewSubject(SubjectModel subject) {
    showResponsiveModal(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      child: _ViewSubjectModal(subject: subject),
    );
  }

  void _editSubject(SubjectModel subject) {
    showResponsiveModal(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      child: _AddSubjectModal(subject: subject),
    );
  }

  Future<void> _deleteSubject(SubjectModel subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text('Remove "${subject.name}" from subjects?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(subjectRepositoryProvider);
      await repo.deleteSubject(subject.id);
      
      ref.invalidate(subjectsListProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${subject.name} deleted')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dioErrorMessage(
              e,
              fallback: 'Could not delete subject',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubjects = ref.watch(subjectsListProvider);
    final asyncPrograms = ref.watch(programsProvider);

    return AppScaffold(
      title: 'Subjects',
      subtitle: 'ACADEMICS',
      currentRoute: '/subjects',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      body: asyncSubjects.when(
        skipLoadingOnReload: true,
        data: (apiList) {
          final programs = asyncPrograms.value;
          final filtered = _filteredFromApi(apiList, programs);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubjectsCard(
                searchCtrl: _searchCtrl,
                status: _statusFilter,
                onSearch: (value) => setState(() => _search = value),
                onStatus: (value) {
                  if (value == null) return;
                  setState(() => _statusFilter = value);
                },
                onCreate: () => showResponsiveModal(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.7),
                  child: const _AddSubjectModal(),
                ),
                onView: _viewSubject,
                onEdit: _editSubject,
                onDelete: _deleteSubject,
                onExport: () => _exportSubjectsCsv(filtered),
                subjects: filtered,
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(subjectsListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _exportSubjectsCsv(List<SubjectModel> list) {
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subject records to export.')),
      );
      return;
    }

    final StringBuffer csv = StringBuffer();
    csv.writeln('Subject Name,Code,Program,Stage,Credits,Practical,Teacher');

    for (final item in list) {
      final name = item.name.replaceAll('"', '""');
      final code = item.code.replaceAll('"', '""');
      final program = item.program.replaceAll('"', '""');
      final stage = item.stage.replaceAll('"', '""');
      final credits = item.credits;
      final practical = item.practical ? 'Yes' : 'No';
      final teacher = item.teacher.replaceAll('"', '""');

      csv.writeln('"$name","$code","$program","$stage",$credits,"$practical","$teacher"');
    }

    final csvString = csv.toString();
    final fileName = 'Subjects_Export_${DateTime.now().toLocal().toString().split(' ')[0]}.csv';

    csv_helper.saveAndShareCsv(
      csvString: csvString,
      fileName: fileName,
    );
  }
}

class _SubjectsCard extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String status;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final VoidCallback onCreate;
  final ValueChanged<SubjectModel> onView;
  final ValueChanged<SubjectModel> onEdit;
  final ValueChanged<SubjectModel> onDelete;
  final VoidCallback onExport;
  final List<SubjectModel> subjects;

  const _SubjectsCard({
    required this.searchCtrl,
    required this.status,
    required this.onSearch,
    required this.onStatus,
    required this.onCreate,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: isMobile
                ? _SubjectsMobileToolbar(
                    searchCtrl: searchCtrl,
                    status: status,
                    onSearch: onSearch,
                    onStatus: onStatus,
                    onCreate: onCreate,
                    onExport: onExport,
                  )
                : _SubjectsDesktopToolbar(
                    searchCtrl: searchCtrl,
                    status: status,
                    onSearch: onSearch,
                    onStatus: onStatus,
                    onCreate: onCreate,
                    onExport: onExport,
                  ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          if (isMobile)
            ...subjects.map(
              (subject) => _SubjectMobileRow(
                subject: subject,
                onView: () => onView(subject),
                onEdit: () => onEdit(subject),
                onDelete: () => onDelete(subject),
              ),
            )
          else
            _SubjectsTable(
              subjects: subjects,
              onView: onView,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
        ],
      ),
    );
  }
}

class _SubjectsDesktopToolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String status;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final VoidCallback onCreate;
  final VoidCallback onExport;

  const _SubjectsDesktopToolbar({
    required this.searchCtrl,
    required this.status,
    required this.onSearch,
    required this.onStatus,
    required this.onCreate,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 400,
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            decoration: const InputDecoration(
              hintText: 'Search records',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 140,
          child: _SubjectFilterDropdown(
            value: status,
            onChanged: onStatus,
          ),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_alt_outlined),
          label: const Text('Filters'),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Export'),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Subject'),
        ),
      ],
    );
  }
}

class _SubjectsMobileToolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String status;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final VoidCallback onCreate;
  final VoidCallback onExport;

  const _SubjectsMobileToolbar({
    required this.searchCtrl,
    required this.status,
    required this.onSearch,
    required this.onStatus,
    required this.onCreate,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchCtrl,
          onChanged: onSearch,
          decoration: const InputDecoration(
            hintText: 'Search records',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SubjectFilterDropdown(
                value: status,
                onChanged: onStatus,
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filters'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Subject'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubjectFilterDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _SubjectFilterDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(),
      items: const [
        DropdownMenuItem(
          value: 'All Status',
          child: Text('All Status'),
        ),
        DropdownMenuItem(
          value: 'Practical Only',
          child: Text('Practical'),
        ),
        DropdownMenuItem(
          value: 'Theory Only',
          child: Text('Theory'),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SubjectsTable extends StatelessWidget {
  final List<SubjectModel> subjects;
  final ValueChanged<SubjectModel> onView;
  final ValueChanged<SubjectModel> onEdit;
  final ValueChanged<SubjectModel> onDelete;

  const _SubjectsTable({
    required this.subjects,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
          child: Row(
            children: const [
              _SubjectsHeaderCell(label: 'SUBJECT', flex: 28),
              _SubjectsHeaderCell(label: 'CODE', flex: 14),
              _SubjectsHeaderCell(label: 'PROGRAM', flex: 14),
              _SubjectsHeaderCell(label: 'STAGE', flex: 10),
              _SubjectsHeaderCell(label: 'CREDITS', flex: 10),
              _SubjectsHeaderCell(label: 'PRACTICAL', flex: 14),
              _SubjectsHeaderCell(label: 'TEACHER', flex: 16),
              _SubjectsHeaderCell(label: 'ACTIONS', flex: 14),
            ],
          ),
        ),
        ...subjects.map(
          (subject) => _SubjectDesktopRow(
            subject: subject,
            onView: () => onView(subject),
            onEdit: () => onEdit(subject),
            onDelete: () => onDelete(subject),
          ),
        ),
      ],
    );
  }
}

class _SubjectDesktopRow extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectDesktopRow({
    required this.subject,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 28,
            child: Row(
              children: [
                _SubjectAvatar(code: subject.program),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subject.meta,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              subject.code,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(flex: 14, child: Text(subject.program)),
          Expanded(flex: 10, child: Text(subject.stage)),
          Expanded(
            flex: 10,
            child: Text('${subject.credits} cr'),
          ),
          Expanded(
            flex: 14,
            child: BadgeChip(
              label: subject.practical ? 'Yes' : 'No',
              tone: subject.practical ? BadgeTone.success : BadgeTone.muted,
            ),
          ),
          Expanded(flex: 16, child: Text(subject.teacher)),
          Expanded(
            flex: 14,
            child: Row(
              children: [
                _SubjectAction(
                  icon: Icons.visibility_outlined,
                  onTap: onView,
                ),
                const SizedBox(width: 8),
                _SubjectAction(
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _SubjectAction(
                  icon: Icons.delete_outline_rounded,
                  onTap: onDelete,
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectMobileRow extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectMobileRow({
    required this.subject,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SubjectAvatar(code: subject.program),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject.meta,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BadgeChip(
                label: subject.code,
                tone: BadgeTone.primary,
              ),
              BadgeChip(
                label: '${subject.credits} cr',
                tone: BadgeTone.accent,
              ),
              BadgeChip(
                label: subject.practical ? 'Yes' : 'No',
                tone: subject.practical ? BadgeTone.success : BadgeTone.muted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${subject.program} · ${subject.stage}'),
          const SizedBox(height: 6),
          Text(subject.teacher),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onView,
                  child: const Text('View'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectsHeaderCell extends StatelessWidget {
  final String label;
  final int flex;

  const _SubjectsHeaderCell({
    required this.label,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SubjectAvatar extends StatelessWidget {
  final String code;

  const _SubjectAvatar({
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        code.split(' ').first,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SubjectAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _SubjectAction({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        ),
      ),
    );
  }
}

class _ViewSubjectModal extends StatelessWidget {
  final SubjectModel subject;

  const _ViewSubjectModal({required this.subject});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CimsModal(
      title: 'Subject Details',
      subtitle: 'View academic subject information',
      actionLabel: 'Close',
      onAction: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDetailRow(context, 'Subject Name', subject.name, isDark),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Subject Code', subject.code, isDark),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Program', subject.program, isDark),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Stage', subject.stage, isDark),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Credits', '${subject.credits} cr', isDark),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Practical Included', subject.practical ? 'Yes' : 'No', isDark),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Assigned Teacher', subject.teacher, isDark),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddSubjectModal extends ConsumerStatefulWidget {
  final SubjectModel? subject;

  const _AddSubjectModal({super.key, this.subject});

  @override
  ConsumerState<_AddSubjectModal> createState() => _AddSubjectModalState();
}

class _AddSubjectModalState extends ConsumerState<_AddSubjectModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _creditsCtrl;
  
  bool _hasPractical = false;
  bool _saving = false;

  int? _selectedProgramId;
  int? _selectedStage;
  int? _selectedTeacherId;

  bool get _isEdit => widget.subject != null;

  @override
  void initState() {
    super.initState();
    final s = widget.subject;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _codeCtrl = TextEditingController(text: s?.code ?? '');
    _creditsCtrl = TextEditingController(text: s?.credits.toString() ?? '3');
    _hasPractical = s?.practical ?? false;

    if (s != null) {
      _selectedProgramId = s.programId;
      _selectedStage = s.stageNum;
      _selectedTeacherId = s.apiModel.assignedTeacher?.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _creditsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProgramId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program')),
      );
      return;
    }

    if (_selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a stage')),
      );
      return;
    }

    final credits = double.tryParse(_creditsCtrl.text.trim());
    if (credits == null || credits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid credit hours')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(subjectRepositoryProvider);
      final staffRepo = ref.read(staffRepositoryProvider);
      final currentSession = await ref.read(currentAcademicSessionProvider.future);

      if (_selectedTeacherId != null && currentSession == null) {
        throw Exception('No active academic session found. Cannot assign teacher.');
      }

      SubjectApiModel savedSubject;
      if (_isEdit) {
        savedSubject = await repo.updateSubject(
          id: widget.subject!.id,
          name: _nameCtrl.text.trim(),
          code: _codeCtrl.text.trim(),
          creditHours: credits,
          hasPractical: _hasPractical,
        );

        final prevAssignment = widget.subject!.apiModel.assignedTeacher;
        
        if (prevAssignment != null && prevAssignment.id != _selectedTeacherId) {
          await staffRepo.removeSubjectAssignment(
            staffId: prevAssignment.id,
            assignmentId: prevAssignment.assignmentId,
          );
        }

        if (_selectedTeacherId != null && (_selectedTeacherId != prevAssignment?.id)) {
          if (currentSession != null) {
            await staffRepo.assignSubject(
              staffId: _selectedTeacherId!,
              subjectId: savedSubject.id,
              sessionId: currentSession.id,
              role: 'BOTH',
              section: 'Morning',
            );
          }
        }
      } else {
        savedSubject = await repo.createSubject(
          programId: _selectedProgramId!,
          name: _nameCtrl.text.trim(),
          code: _codeCtrl.text.trim(),
          stage: _selectedStage!,
          creditHours: credits,
          hasPractical: _hasPractical,
        );

        if (_selectedTeacherId != null && currentSession != null) {
          await staffRepo.assignSubject(
            staffId: _selectedTeacherId!,
            subjectId: savedSubject.id,
            sessionId: currentSession.id,
            role: 'BOTH',
            section: 'Morning',
          );
        }
      }

      ref.invalidate(subjectsListProvider);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Subject updated' : 'Subject created',
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dioErrorMessage(
              e,
              fallback: 'Could not save subject',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final programsAsync = ref.watch(programsProvider);
    final staffAsync = ref.watch(staffListProvider(null));

    return CimsModal(
      title: _isEdit ? 'Edit Subject' : 'Add Subject',
      subtitle: _isEdit ? 'Modify academic subject details' : 'Create an academic subject',
      actionLabel: _isEdit ? 'Save Changes' : 'Save Subject',
      isLoading: _saving,
      onAction: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CimsFormField(
              label: 'Subject Name',
              controller: _nameCtrl,
              hint: 'e.g. Microbiology',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Subject name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            CimsFormField(
              label: 'Code',
              controller: _codeCtrl,
              hint: 'e.g. BS-MT-S2-MICRO',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Subject code is required'
                  : null,
            ),
            const SizedBox(height: 16),
            programsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load programs: $e'),
              data: (programs) {
                final ProgramModel? selectedProgram;
                if (_selectedProgramId != null) {
                  final matches = programs.where((p) => p.id == _selectedProgramId);
                  selectedProgram = matches.isNotEmpty ? matches.first : null;
                } else {
                  selectedProgram = null;
                }

                return Column(
                  children: [
                    CimsDropdownField<int>(
                      label: 'Program',
                      value: _selectedProgramId,
                      items: programs.map((p) => p.id).toList(),
                      itemLabel: (id) => programs.firstWhere((p) => p.id == id).name,
                      onChanged: _isEdit ? (_) {} : (v) {
                        if (v == null) return;
                        setState(() {
                          _selectedProgramId = v;
                          _selectedStage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedProgramId != null)
                      ref.watch(programStagesProvider(_selectedProgramId!)).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Could not load stages: $e'),
                        data: (stages) {
                          final stageFieldLabel = selectedProgram?.programType == 'Annual'
                              ? 'Stage / Year'
                              : selectedProgram?.programType == 'Diploma'
                                  ? 'Stage / Term'
                                  : 'Stage / Semester';

                          return CimsDropdownField<int>(
                            label: stageFieldLabel,
                            value: _selectedStage,
                            items: stages.map((s) => s.stage).toList(),
                            itemLabel: (stageNum) => stages.firstWhere((s) => s.stage == stageNum).label,
                            onChanged: _isEdit ? (_) {} : (v) {
                              if (v == null) return;
                              setState(() => _selectedStage = v);
                            },
                          );
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                        ),
                        child: Text(
                          'Select a program to choose stage',
                          style: AppTextStyles.bodySm.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            CimsFormField(
              label: 'Credits',
              controller: _creditsCtrl,
              hint: '3',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Credit hours required';
                final num = double.tryParse(v.trim());
                if (num == null || num <= 0 || num > 6) {
                  return 'Enter value between 0.5 and 6';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            staffAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load teachers: $e'),
              data: (staffList) {
                final teachers = staffList.where((s) =>
                  s.isActive && ['MEDICAL', 'ACADEMIC', 'NURSING'].contains(s.category.toUpperCase())
                ).toList();

                return CimsDropdownField<int?>(
                  label: 'Teacher',
                  value: _selectedTeacherId,
                  items: [null, ...teachers.map((t) => t.id)],
                  itemLabel: (id) => id == null ? 'No Teacher Assigned' : teachers.firstWhere((t) => t.id == id).fullName,
                  onChanged: (v) {
                    setState(() => _selectedTeacherId = v);
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'HAS PRACTICAL / LAB',
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.text,
                ),
              ),
              subtitle: Text(
                'Include separate practical marks',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              value: _hasPractical,
              onChanged: (v) => setState(() => _hasPractical = v),
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
