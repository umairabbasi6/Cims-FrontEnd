import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/teacher/dashboard/providers/teacher_dashboard_provider.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/utils/csv_export_helper.dart' as csv_helper;

class TeacherClassesScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const TeacherClassesScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends ConsumerState<TeacherClassesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'All Status';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterClasses(List<Map<String, dynamic>> list) {
    return list.where((item) {
      final name = item['name'].toString().toLowerCase();
      final code = item['code'].toString().toLowerCase();
      final className = item['className'].toString().toLowerCase();
      final query = _search.toLowerCase();

      final matchesSearch = _search.isEmpty ||
          name.contains(query) ||
          code.contains(query) ||
          className.contains(query);

      final matchesStatus = _statusFilter == 'All Status' ||
          item['status'].toString() == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _exportClassesCsv(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No class records to export.')),
      );
      return;
    }

    final StringBuffer csv = StringBuffer();
    csv.writeln('Subject,Code,Class,Next Session,Students,Avg Attendance,Status');

    for (final item in list) {
      final name = item['name'].toString().replaceAll('"', '""');
      final code = item['code'].toString().replaceAll('"', '""');
      final className = item['className'].toString().replaceAll('"', '""');
      final nextSession = item['nextSession'].toString().replaceAll('"', '""');
      final students = item['students'];
      final avgAtt = '${item['avgAttendance']}%';
      final status = item['status'].toString();

      csv.writeln('"$name","$code","$className","$nextSession",$students,"$avgAtt","$status"');
    }

    final csvString = csv.toString();
    final fileName = 'My_Classes_Export_${DateTime.now().toLocal().toString().split(' ')[0]}.csv';

    csv_helper.saveAndShareCsv(
      csvString: csvString,
      fileName: fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(teacherDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    return AppScaffold(
      title: 'My Classes',
      subtitle: 'TEACHING',
      currentRoute: '/sessions',
      role: 'teacher',
      onNavigate: widget.onNavigate,
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e'),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Classes not found.'));
          }

          final filteredList = _filterClasses(data.assignedClassesList);

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Column(
              children: [
                // TOOLBAR
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: isMobile
                      ? _buildMobileToolbar(filteredList)
                      : _buildDesktopToolbar(filteredList),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                // CLASSES VIEW
                if (filteredList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No classes match the filter criteria.',
                        style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                      ),
                    ),
                  )
                else if (isMobile)
                  ...filteredList.map((c) => _buildMobileClassRow(c, isDark))
                else
                  _buildDesktopTable(filteredList, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopToolbar(List<Map<String, dynamic>> list) {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              hintText: 'Search classes or subjects...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(value: 'All Status', child: Text('All Status')),
              DropdownMenuItem(value: 'Active', child: Text('Active')),
              DropdownMenuItem(value: 'Review', child: Text('Review')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _statusFilter = v);
            },
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () => _exportClassesCsv(list),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Export CSV'),
        ),
      ],
    );
  }

  Widget _buildMobileToolbar(List<Map<String, dynamic>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _search = v),
          decoration: const InputDecoration(
            hintText: 'Search classes or subjects...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _statusFilter,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'All Status', child: Text('All Status')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Review', child: Text('Review')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _statusFilter = v);
                },
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _exportClassesCsv(list),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Export'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopTable(List<Map<String, dynamic>> list, bool isDark) {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
          child: Row(
            children: [
              Expanded(flex: 30, child: Text('SUBJECT', style: AppTextStyles.labelSm)),
              Expanded(flex: 18, child: Text('CLASS', style: AppTextStyles.labelSm)),
              Expanded(flex: 22, child: Text('NEXT SESSION', style: AppTextStyles.labelSm)),
              Expanded(flex: 12, child: Text('STUDENTS', style: AppTextStyles.labelSm)),
              Expanded(flex: 20, child: Text('AVG ATTENDANCE', style: AppTextStyles.labelSm)),
              Expanded(flex: 12, child: Text('STATUS', style: AppTextStyles.labelSm)),
            ],
          ),
        ),
        ...list.map((c) {
          final initials = c['name'].toString().substring(0, 1).toUpperCase();
          final att = c['avgAttendance'] as int;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 30,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['name'],
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              c['code'],
                              style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 18,
                  child: Text(
                    c['className'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 22,
                  child: Text(
                    c['nextSession'],
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: Text(
                    '${c['students']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: att / 100.0,
                            minHeight: 6,
                            backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              att >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$att%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: BadgeChip(
                    label: c['status'],
                    tone: c['status'] == 'Active' ? BadgeTone.success : BadgeTone.warning,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMobileClassRow(Map<String, dynamic> c, bool isDark) {
    final initials = c['name'].toString().substring(0, 1).toUpperCase();
    final att = c['avgAttendance'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['name'],
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${c['code']} · ${c['className']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                    ),
                  ],
                ),
              ),
              BadgeChip(
                label: c['status'],
                tone: c['status'] == 'Active' ? BadgeTone.success : BadgeTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEXT SESSION', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                  const SizedBox(height: 2),
                  Text(c['nextSession'], style: const TextStyle(fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('STUDENTS', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                  const SizedBox(height: 2),
                  Text('${c['students']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('ATTENDANCE  ', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: att / 100.0,
                    minHeight: 5,
                    backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      att >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$att%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
