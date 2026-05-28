import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/stat_card.dart';
import 'package:cims/core/session/app_session.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/programs/add_program_modal.dart';
import 'package:cims/features/admin/programs/models/program_model.dart';
import 'package:cims/features/admin/programs/providers/program_provider.dart';
import 'package:cims/core/network/dio_error_message.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/utils/csv_export_helper.dart' as csv_helper;
import 'package:dio/dio.dart';

// ═════════════════════════════════════════════════════
// SCREEN
// ═════════════════════════════════════════════════════

class ProgramsScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const ProgramsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'All Status';
  String _typeFilter = 'All Types';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProgramModel> _getFiltered(List<ProgramModel> programsList) {
    return programsList.where((program) {
      final searchMatch = _search.isEmpty ||
          program.name.toLowerCase().contains(_search.toLowerCase()) ||
          program.department.name
              .toLowerCase()
              .contains(_search.toLowerCase());

      final statusMatch = _statusFilter == 'All Status' ||
          (_statusFilter == 'Active' && program.isActive) ||
          (_statusFilter == 'Inactive' && !program.isActive);

      final typeMatch = _typeFilter == 'All Types' ||
          program.programType == _typeFilter;

      return searchMatch && statusMatch && typeMatch;
    }).toList();
  }

  Future<void> _openEdit(ProgramModel program) async {
    final updated = await showResponsiveModal<bool>(
      context: context,
      child: AddProgramModal(program: program),
    );
    if (updated == true) {
      ref.invalidate(programsProvider);
    }
  }

  Future<void> _confirmDelete(ProgramModel program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete program?'),
        content: Text('Remove "${program.name}" from active programs?'),
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
      await ref.read(programRepositoryProvider).deleteProgram(program.id);
      ref.invalidate(programsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${program.name} deleted')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dioErrorMessage(
              e,
              fallback: 'Could not delete program',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final programsState = ref.watch(programsProvider);
    final allPrograms = programsState.value ?? [];
    final filteredPrograms = _getFiltered(allPrograms);
    final activePrograms = allPrograms.where((p) => p.isActive).length;
    final semesterPrograms = allPrograms.where((p) => p.programType == 'Semester').length;
    final totalStudents = 0;

    return AppScaffold(
      title: 'Programs Management',
      subtitle: 'ACADEMICS',
      currentRoute: '/programs',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _ProgramStats(
            programs: allPrograms.length,
            active: activePrograms,
            semester: semesterPrograms,
            students: totalStudents,
          ),
          const SizedBox(height: 16),
          _Toolbar(
            controller: _searchCtrl,
            status: _statusFilter,
            type: _typeFilter,
            onSearch: (value) => setState(() => _search = value),
            onStatus: (value) => setState(() => _statusFilter = value ?? 'All Status'),
            onType: (value) => setState(() => _typeFilter = value ?? 'All Types'),
            onExport: () => _exportProgramsCsv(filteredPrograms),
            onAdd: () async {
              final created = await showResponsiveModal<bool>(
                context: context,
                child: const AddProgramModal(),
              );
              if (created == true) {
                ref.invalidate(programsProvider);
              }
            },
          ),
          const SizedBox(height: 16),
          if (programsState.isLoading && allPrograms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredPrograms.isEmpty)
            const _EmptyState()
          else if (Responsive.isMobile(context))
            _MobilePrograms(
              programs: filteredPrograms,
              onEdit: _openEdit,
              onDelete: _confirmDelete,
            )
          else
            _ProgramsTable(
              programs: filteredPrograms,
              onEdit: _openEdit,
              onDelete: _confirmDelete,
            ),
        ],
      ),
    );
  }

  void _exportProgramsCsv(List<ProgramModel> list) {
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No program records to export.')),
      );
      return;
    }

    final StringBuffer csv = StringBuffer();
    csv.writeln('Name,Department,Total Stages,Award,Program Type,Status');

    for (final item in list) {
      final name = item.name.replaceAll('"', '""');
      final dept = item.department.name.replaceAll('"', '""');
      final stages = item.totalStages;
      final award = (item.award ?? '').replaceAll('"', '""');
      final type = item.programType.replaceAll('"', '""');
      final status = item.isActive ? 'Active' : 'Inactive';

      csv.writeln('"$name","$dept",$stages,"$award","$type","$status"');
    }

    final csvString = csv.toString();
    final fileName = 'Programs_Export_${DateTime.now().toLocal().toString().split(' ')[0]}.csv';

    csv_helper.saveAndShareCsv(
      csvString: csvString,
      fileName: fileName,
    );
  }
}

// ═════════════════════════════════════════════════════
// STATS
// ═════════════════════════════════════════════════════════

class _ProgramStats extends StatelessWidget {
  final int programs;
  final int active;
  final int semester;
  final int students;

  const _ProgramStats({
    required this.programs,
    required this.active,
    required this.semester,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    final card1 = StatCard(
      label: 'Programs',
      value: programs.toString(),
      icon: const Icon(Icons.school_rounded),
    );

    final card2 = StatCard(
      label: 'Active',
      value: active.toString(),
      trend: '+5%',
      tone: StatTone.success,
      icon: const Icon(Icons.check_circle_outline_rounded),
    );

    final card3 = StatCard(
      label: 'Semester',
      value: semester.toString(),
      icon: const Icon(Icons.calendar_today_rounded),
    );

    final card4 = StatCard(
      label: 'Students',
      value: students.toString(),
      icon: const Icon(Icons.people_alt_rounded),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card1,
          const SizedBox(height: 12),
          card2,
          const SizedBox(height: 12),
          card3,
          const SizedBox(height: 12),
          card4,
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card1),
                const SizedBox(width: 12),
                Expanded(child: card2),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card3),
                const SizedBox(width: 12),
                Expanded(child: card4),
              ],
            ),
          ),
        ],
      );
    }

    // Desktop
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: card1),
          const SizedBox(width: 12),
          Expanded(child: card2),
          const SizedBox(width: 12),
          Expanded(child: card3),
          const SizedBox(width: 12),
          Expanded(child: card4),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController controller;
  final String status;
  final String type;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onType;
  final VoidCallback onExport;
  final VoidCallback onAdd;

  const _Toolbar({
    required this.controller,
    required this.status,
    required this.type,
    required this.onSearch,
    required this.onStatus,
    required this.onType,
    required this.onExport,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchField = SizedBox(
      width: isMobile ? double.infinity : 280,
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: 'Search programs...',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
      ),
    );

    final statusBox = _DropdownBox(
      value: status,
      items: const ['All Status', 'Active', 'Inactive'],
      onChanged: onStatus,
    );

    final typeBox = _DropdownBox(
      value: type,
      items: const ['All Types', 'Semester', 'Annual'],
      onChanged: onType,
    );

    final filterButton = _ToolbarButton(
      icon: Icons.filter_list_rounded,
      label: 'Filters',
      onTap: () {},
      isDark: isDark,
    );

    final exportBtn = OutlinedButton.icon(
      onPressed: onExport,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.darkText : AppColors.text,
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Icons.file_download_outlined, size: 18),
      label: const Text('Export', style: TextStyle(fontWeight: FontWeight.w600)),
    );

    final addBtn = ElevatedButton.icon(
      onPressed: onAdd,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Add Program', style: TextStyle(fontWeight: FontWeight.w600)),
    );

    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              statusBox,
              typeBox,
              filterButton,
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              exportBtn,
              addBtn,
            ],
          ),
        ],
      );
    }

    if (screenWidth < 1100) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          searchField,
          statusBox,
          typeBox,
          filterButton,
          exportBtn,
          addBtn,
        ],
      );
    }

    return Row(
      children: [
        searchField,
        const SizedBox(width: 12),
        statusBox,
        const SizedBox(width: 12),
        typeBox,
        const SizedBox(width: 12),
        filterButton,
        const Spacer(),
        exportBtn,
        const SizedBox(width: 12),
        addBtn,
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownBox extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        dropdownColor: isDark ? AppColors.darkSurfaceAlt : Colors.white,
        style: AppTextStyles.bodySm.copyWith(
          color: isDark ? AppColors.darkText : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        items: items.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════
// TABLE
// ═════════════════════════════════════════════════════

class _ProgramsTable extends StatelessWidget {
  final List<ProgramModel> programs;
  final void Function(ProgramModel) onEdit;
  final void Function(ProgramModel) onDelete;

  const _ProgramsTable({
    required this.programs,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1200,
          child: Column(
            children: [
              _TableHeader(border: border),
              ...programs.map(
                (program) => _ProgramRow(
                  program: program,
                  border: border,
                  onEdit: () => onEdit(program),
                  onDelete: () => onDelete(program),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final Color border;

  const _TableHeader({
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final columns = [
      'PROGRAM',
      'DEPARTMENT',
      'DURATION',
      'LEVEL',
      'TYPE',
      'STATUS',
      'ACTIONS',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: columns.asMap().entries.map((entry) {
          return Expanded(
            flex: entry.key == 0 ? 3 : entry.key == 6 ? 2 : 1,
            child: Text(
              entry.value,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProgramRow extends StatefulWidget {
  final ProgramModel program;
  final Color border;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProgramRow({
    required this.program,
    required this.border,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProgramRow> createState() => _ProgramRowState();
}

class _ProgramRowState extends State<_ProgramRow> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = [
      AppColors.primary,
      AppColors.accent,
      AppColors.purple,
      AppColors.warning,
      AppColors.pink,
    ][widget.program.name.hashCode % 5];

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: hovered
            ? (isDark ? AppColors.darkSurfaceHover : AppColors.surfaceHover)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.program.name.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.program.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.text,
                          ),
                        ),
                        Text(
                          '${widget.program.department.name} · ${widget.program.award ?? '-'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSm.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                widget.program.department.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${widget.program.totalStages} Stages',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                widget.program.award ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                widget.program.programType,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: BadgeChip.status(widget.program.isActive ? 'Active' : 'Inactive'),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.visibility_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    onTap: widget.onDelete,
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════
// MOBILE CARDS
// ═════════════════════════════════════════════════════

class _MobilePrograms extends StatelessWidget {
  final List<ProgramModel> programs;
  final void Function(ProgramModel) onEdit;
  final void Function(ProgramModel) onDelete;

  const _MobilePrograms({
    required this.programs,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: programs
          .map(
            (program) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MobileProgramCard(
                program: program,
                onEdit: () => onEdit(program),
                onDelete: () => onDelete(program),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MobileProgramCard extends StatelessWidget {
  final ProgramModel program;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobileProgramCard({
    required this.program,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  program.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              BadgeChip.status(program.isActive ? 'Active' : 'Inactive'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BadgeChip(
                label: program.department.name,
                tone: BadgeTone.primary,
              ),
              BadgeChip(
                label: program.programType,
                tone: BadgeTone.success,
              ),
              BadgeChip(
                label: program.award ?? '-',
                tone: BadgeTone.accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('${program.totalStages} Stages')),
              Expanded(child: Text('0 Students')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.visibility_outlined,
                  size: 16,
                ),
                label: const Text('View'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                  ),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════
// EMPTY STATE
// ═════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 54,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            'No programs found',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing filters or search query.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color ?? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        ),
      ),
    );
  }
}
